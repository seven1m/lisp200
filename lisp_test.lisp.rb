[
  [:assert=, 0, [:+], nil],
  [:assert=, 4, [:+, 4], nil],
  [:assert=, 6, [:+, 4, 2], nil],
  [:assert=, 7, [:+, 4, 2, 1], nil],
  [:assert=, 13, [:+, 6, 4, 2, 1], nil],
  [:assert=, -1, [:-, 1], nil],
  [:assert=, 2, [:-, 4, 2], nil],
  [:assert=, 0, [:-, 4, 2, 2], nil],
  [:assert=, 1, [:*], nil],
  [:assert=, 4, [:*, 4], nil],
  [:assert=, 8, [:*, 4, 2], nil],
  [:assert=, 24, [:*, 4, 2, 3], nil],
  [:assert=, 0.5, [:/, 2], nil],
  [:assert=, 4, [:/, 24, 6], nil],
  [:assert=, 2, [:/, 24, 6, 2], nil],
  [:assert=, "hello world",
             [:str, "hello", " ", "world"],
             nil],
  [:assert=, [:cons, 1, [:cons, 3, [:cons, 5, nil]]],
             [:filter, :odd?, [:cons, 1, [:cons, 2, [:cons, 3, [:cons, 4, [:cons, 5, nil]]]]]],
             nil],
  #[:assert=, 0, [:let, [], 0], nil],
  #[:assert=, 1, [:let, [:a, 1], :a], nil],
]