struct Point {
  x :: Number
  y :: Number
}

rp :: () -> Point = () -> { x : 3, y : 5}
rp().x.y

# console.log 'done'