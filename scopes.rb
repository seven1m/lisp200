l1 = -> {
  x = 1
  l2 = ->(x=nil) {
    x = 2
    p x => 2
  }
  p x => 1
  l2.()
  p x => 1
}
l1.()

v = 1
letrec = ->(x = v + 1, y = x + 1, z = y * 2) {
  p v => 1
  p x => 2
  p y => 3
  p z => 6
}
letrec.()
