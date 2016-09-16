# CustomSearch-1.0
Framework for building search engines in lua. Handles most of the heavy work for you, such as concept separation,
non ascii character support, logical operators and user criteria selection.

### API Overview
|Name|Description|
|:--|:--|
| :Matches(article, search, filters) | Returns wether the given `article` matches the `search` query using the `filters` structure as the criteria. |
| :Find(search, field1, field2, ...) | Returns wether the `search` string is present on any of the string `fields` provided.  |
| :Compare(operator, a, b) | Returns an inequality operation between `a` and `b`, where `operator` is the string representation of the operation. |

### Filters Specification
The `filters` data structure allows you to easly build a search engine of your own.
`filters` is a set of filter objects. Each filter is akin to an independent criteria of the engine: 
if any filter approves the `article` for a given `search` query, the `article` is approved.

For an object to be a filter, it must implement the following fields:

|Name|Description|
|:--|:--|
| :canSearch(operator, search, article) | Returns wether the filter can process this query. If not `.match` will not be called and this filter will not be considered for the query. Can return any number of arguments. |
| :match(article, operator, data1, data2, ...) | Returns wether this filter approves the `article` for a given query. 'data1', 'data2', etc are the return arguments of :canSearch. |
| .tags | Optional. Array of identifiers that can be placed at the beggining of a `search` query to perform a `:Match` using only this filter. |

### Examples
    local Lib = LibStub('CustomSearch-1.0')
    
    Lib:Find('(João)', 'Roses are red', 'Violets are (jóaô)', 'Wait that was wrong') -- true
    Lib:Find('banana', 'Roses are red', 'Violets are jóaô', 'Wait that was wrong') -- false
    
    Lib:Compare('<', 3, 4) -- true
    Lib:Compare('>', 3, 4) -- false
    Lib:Compare('>=', 5, 5) -- true
    
    local Filters = {
      isBanana = {
        tags = {'b', 'ba'},
        
        canSearch = function(self, operator, search)
          return true
        end,
        
        match = function(self, article, operator, search)
          return Lib:Find(article, 'banana')
        end
      },
      
      searchingApple = {
        tags = {'a', 'app'},
        
        canSearch = function(self, operator, search)
          if not operator then
            return search
          end
        end,
        
        match = function(self, article, operator, search)
          return Lib:Find(search, 'apple')
        end
      }
    }
    
    Lib:Match('Banana', '', Filters) -- true
    Lib:Match('', 'Apple', Filters) -- true
    Lib:Match('', '> Apple', Filters) -- false
    Lib:Match('Apple', 'Banana', Filters) -- false
    Lib:Match('', 'b:Apple', Filters) -- false
    Lib:Match('', 'a:Apple', Filters) -- true
    
