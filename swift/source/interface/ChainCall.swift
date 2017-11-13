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

public protocol InsertChainCallInterface {
    func prepareInsert(ofClass cls: TableCoding.Type, into table: String) throws -> Insert 
    func prepareInsertOrReplace(ofClass cls: TableCoding.Type, into table: String) throws -> Insert 
    func prepareInsert(onProperties propertyConvertibleList: PropertyConvertible..., into table: String) throws -> Insert
    func prepareInsertOrReplace(onProperties propertyConvertibleList: PropertyConvertible..., into table: String) throws -> Insert
    func prepareInsert(onProperties propertyConvertibleList: [PropertyConvertible], into table: String) throws -> Insert
    func prepareInsertOrReplace(onProperties propertyConvertibleList: [PropertyConvertible], into table: String) throws -> Insert 
}

extension InsertChainCallInterface where Self: Core {
    public func prepareInsert(ofClass cls: TableCoding.Type, into table: String) throws -> Insert {
        return try Insert(with: self, named: table, on: cls.allProperties, isReplace: false)
    }
    
    public func prepareInsertOrReplace(ofClass cls: TableCoding.Type, into table: String) throws -> Insert  {
        return try Insert(with: self, named: table, on: cls.allProperties, isReplace: true)
    }
    
    public func prepareInsert(onProperties propertyConvertibleList: PropertyConvertible..., into table: String) throws -> Insert {
        return try Insert(with: self, named: table, on: propertyConvertibleList, isReplace: false)
    }
    
    public func prepareInsertOrReplace(onProperties propertyConvertibleList: PropertyConvertible..., into table: String) throws -> Insert {
        return try Insert(with: self, named: table, on: propertyConvertibleList, isReplace: true)
    }
    
    public func prepareInsert(onProperties propertyConvertibleList: [PropertyConvertible], into table: String) throws -> Insert {
        return try Insert(with: self, named: table, on: propertyConvertibleList, isReplace: false)
    }
    
    public func prepareInsertOrReplace(onProperties propertyConvertibleList: [PropertyConvertible], into table: String) throws -> Insert {
        return try Insert(with: self, named: table, on: propertyConvertibleList, isReplace: true)
    }
}

public protocol DeleteChainCallInterface {
    func prepareDelete(from table: String) throws -> Delete
}

extension DeleteChainCallInterface where Self: Core {
    public func prepareDelete(from table: String) throws -> Delete {
        return try Delete(with: self, andTableName: table)
    }
}

public protocol UpdateChainCallInterface {
    func prepareUpdate(table: String, onProperties propertyConvertibleList: PropertyConvertible...) throws -> Update
    func prepareUpdate(table: String, onProperties propertyConvertibleList: [PropertyConvertible]) throws -> Update
}

extension UpdateChainCallInterface where Self: Core {
    public func prepareUpdate(table: String, onProperties propertyConvertibleList: PropertyConvertible...) throws -> Update {
        return try Update(with: self, on: propertyConvertibleList, andTable: table)
    }
    
    public func prepareUpdate(table: String, onProperties propertyConvertibleList: [PropertyConvertible]) throws -> Update {
        return try Update(with: self, on: propertyConvertibleList, andTable: table)
    }
}

public protocol RowSelectChainCallInterface {
    func prepareRowSelect(on columnResultConvertibleList: ColumnResultConvertible..., from tables : [String], isDistinct: Bool) throws -> RowSelect
    func prepareRowSelect(on columnResultConvertibleList: [ColumnResultConvertible], from tables : [String], isDistinct: Bool) throws -> RowSelect
    func prepareRowSelect(on columnResultConvertibleList: ColumnResultConvertible..., from table : String, isDistinct: Bool) throws -> RowSelect
    func prepareRowSelect(on columnResultConvertibleList: [ColumnResultConvertible], from table : String, isDistinct: Bool) throws -> RowSelect 
}

extension RowSelectChainCallInterface where Self: Core {
    public func prepareRowSelect(on columnResultConvertibleList: ColumnResultConvertible..., from tables : [String], isDistinct: Bool = false) throws -> RowSelect {
        return try RowSelect(with: self, results: columnResultConvertibleList, tables: tables, isDistinct: isDistinct)
    }
    
    public func prepareRowSelect(on columnResultConvertibleList: [ColumnResultConvertible], from tables : [String], isDistinct: Bool = false) throws -> RowSelect {
        return try RowSelect(with: self, results: columnResultConvertibleList, tables: tables, isDistinct: isDistinct)
    }
    
    public func prepareRowSelect(on columnResultConvertibleList: ColumnResultConvertible..., from table : String, isDistinct: Bool = false) throws -> RowSelect {
        return try RowSelect(with: self, results: columnResultConvertibleList, tables: [table], isDistinct: isDistinct)
    }
    
    public func prepareRowSelect(on columnResultConvertibleList: [ColumnResultConvertible], from table : String, isDistinct: Bool = false) throws -> RowSelect {
        return try RowSelect(with: self, results: columnResultConvertibleList, tables: [table], isDistinct: isDistinct)
    }
}

public protocol SelectChainCallInterface {
    func prepareSelect(of cls: TableCoding.Type, from table: String, isDistinct: Bool) throws -> Select
    func prepareSelect(on propertyConvertibleList: PropertyConvertible..., from table : String, isDistinct: Bool) throws -> Select
    func prepareSelect(on propertyConvertibleList: [PropertyConvertible], from table : String, isDistinct: Bool) throws -> Select
}

extension SelectChainCallInterface where Self: Core {
    public func prepareSelect(of cls: TableCoding.Type, from table: String, isDistinct: Bool = false) throws -> Select {
        return try Select(with: self, on: cls.allProperties, table: table, isDistinct: isDistinct)
    }
    
    public func prepareSelect(on propertyConvertibleList: PropertyConvertible..., from table : String, isDistinct: Bool = false) throws -> Select {
        return try Select(with: self, on: propertyConvertibleList, table: table, isDistinct: isDistinct)
    }
    
    public func prepareSelect(on propertyConvertibleList: [PropertyConvertible], from table : String, isDistinct: Bool = false) throws -> Select {
        return try Select(with: self, on: propertyConvertibleList, table: table, isDistinct: isDistinct)
    }
}

public protocol MultiSelectChainCallInterface {
    func prepareMultiSelect(on propertyConvertibleList: PropertyConvertible..., from tables: [String]) throws -> MultiSelect
    func prepareMultiSelect(on propertyConvertibleList: [PropertyConvertible], from tables: [String]) throws -> MultiSelect 
}

extension MultiSelectChainCallInterface where Self: Core {
    public func prepareMultiSelect(on propertyConvertibleList: PropertyConvertible..., from tables: [String]) throws -> MultiSelect {
        return try MultiSelect(with: self, on: propertyConvertibleList, tables: tables)
    }
    
    public func prepareMultiSelect(on propertyConvertibleList: [PropertyConvertible], from tables: [String]) throws -> MultiSelect {
        return try MultiSelect(with: self, on: propertyConvertibleList, tables: tables)
    }
}