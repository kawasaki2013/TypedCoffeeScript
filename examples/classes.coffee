class Person
  name :: String
  age  :: Int

  constructor :: String * Int -> ()
  constructor: (name :: String, age :: Int) ->
    @name = name
    @age = age

a :: Person = new Person 'mizchi', 26
name :: String = a.name

class Point
  x :: Int
  y :: Int

struct Size
  width  :: Int
  height :: Int

class Region extends Point implements Size
region :: {x :: Int, width :: Int} = new Region

# class type arguments
class Class<A>
  f :: Int -> Int
  constructor :: A -> ()
  constructor: (a) ->
c = new Class<Int>(1)
