/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

public class HandlePool {
    typealias Wrap = (handlePool: HandlePool, reference: Int)
    
    private static let spin = WCDB.Spin()
    private static var pools: [String: Wrap] = [:]
    
    static func getPool(withPath path: String, defaultConfigs: Configs) -> RecyclableHandlePool {
        spin.lock(); defer { spin.unlock() }
        var handlePool: HandlePool?
        if var wrap = pools[path] {
            handlePool = wrap.handlePool
            wrap.reference += 1
        }else {
            handlePool = HandlePool(withPath: path, defaultConfigs: defaultConfigs)
            pools[path] = (handlePool!, 1)
        }
        return Recyclable(handlePool!, onRecycled: {
            spin.lock(); defer { spin.unlock() }
            var wrap = pools[path]!
            wrap.reference -= 1
            if wrap.reference == 0 {
                pools.removeValue(forKey: path)
            }
        })
    }
    
    static func getPool(with tag: Tag) -> RecyclableHandlePool? {
        spin.lock(); defer { spin.unlock() }
        for (path, var wrap) in pools {
            guard wrap.handlePool.tag == tag else {
                continue
            }
            wrap.reference += 1
            return Recyclable(wrap.handlePool, onRecycled: {
                spin.lock(); defer { spin.unlock() }
                var wrap = pools[path]!
                wrap.reference -= 1
                if wrap.reference == 0 {
                    pools.removeValue(forKey: path)
                }
            })
        }
        return nil
    }
    
    static let hardwareConcurrency = ProcessInfo.processInfo.processorCount 

    typealias HandleWrap = (handle: Handle, configs: Configs)
    private let handles = ConcurrentList<HandleWrap>(withCapacityCap: hardwareConcurrency)
    
    var tag: Tag? = nil
    let path: String
    private let rwlock = RWLock()
    private let aliveHandleCount = Atomic<Int>(0)
    private var configs: Configs
    
    private init(withPath path: String, defaultConfigs: Configs) {
        self.path = path
        self.configs = defaultConfigs
    }
    
    var isDrained: Bool {
        return aliveHandleCount == 0
    }    

    func fillOne() throws {
        rwlock.lockRead(); defer { rwlock.unlockRead() }
        let handle = try generate()
        if handles.pushBack(handle) {
            aliveHandleCount += 1
        }
    }

    func invoke(handleWrap: inout HandleWrap) throws {
        let newConfigs = self.configs
        if newConfigs != handleWrap.configs {
            try newConfigs.invoke(handle: handleWrap.handle)
            handleWrap.configs = newConfigs
        }
    }
    
    static private let maxConcurrency = 64

    func flowOut() throws -> RecyclableHandle {
        var unlock = true
        rwlock.lockRead(); defer {  if unlock { rwlock.unlockRead() } }
        var handleWrap = handles.popBack()
        if handleWrap == nil {
            guard aliveHandleCount < HandlePool.maxConcurrency else {
                throw Error.reportCore(tag: tag, path: path, operation: .FlowOut, code: .Exceed, message: "The concurrency of database exceeds the max concurrency")
            }
            handleWrap = try generate()
            aliveHandleCount += 1
            if aliveHandleCount > HandlePool.maxConcurrency {
                Error.warning("The concurrency of database: \(tag ?? 0) with \(aliveHandleCount) exceeds the concurrency of hardware: \(HandlePool.maxConcurrency)")
            }
        }
        handleWrap!.handle.tag = self.tag
        try invoke(handleWrap: &handleWrap!)
        unlock = false 
        return RecyclableHandle(handleWrap!, onRecycled: {
            self.flowBack(handleWrap!)
        })
    }
    
    func flowBack(_ handleWrap: HandleWrap) {
        let inserted = handles.pushBack(handleWrap)
        rwlock.unlockRead()
        if inserted {
            aliveHandleCount -= 1
        }
    }
    
    func generate() throws -> HandleWrap {
        let handle = Handle(withPath: path)
        handle.tag = tag
        let configs = self.configs
        try handle.open()
        try configs.invoke(handle: handle)
        return HandleWrap(handle: handle, configs: configs)
    }
    
    func blockade() {
        rwlock.lockWrite()
    }
    
    func unblockade() {
        rwlock.unlockWrite()
    }
    
    var isBlockaded: Bool {
        return rwlock.isWriting
    }
    
    public typealias OnDrained = () throws -> ()
    
    func drain(onDrained: OnDrained?) rethrows {
        rwlock.lockWrite(); defer { rwlock.unlockWrite() }
        let size = handles.clear()
        aliveHandleCount -= size
        if onDrained != nil {
            try onDrained!()
        }
    }
    
    func purgeFreeHandles() {
        rwlock.lockRead(); defer { rwlock.unlockRead() }
        let size = handles.clear()
        aliveHandleCount -= size
    }
    
    public typealias Config = Configs.Callback
    public typealias ConfigOrder = Configs.Order
    
    func setConfig(named name: String, with callback: @escaping Config, orderBy order: ConfigOrder) {
        configs.setConfig(named: name, with: callback, orderBy: order)
    }
    
    func setConfig(named name: String, with callback: @escaping Config) {
        configs.setConfig(named: name, with: callback)
    }

    static func purgeFreeHandlesInAllPool() {
        var handlePools: [HandlePool] = []
        do {
            spin.lock(); defer { spin.unlock() }
            for (_, wrap) in pools {
                handlePools.append(wrap.handlePool)
            }
        }
        for handlePool in handlePools {
            handlePool.purgeFreeHandles()
        }
    }
}