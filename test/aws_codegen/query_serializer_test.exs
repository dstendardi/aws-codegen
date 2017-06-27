defmodule AWS.CodeGen.QuerySerializerTest do
  use ExUnit.Case
  doctest AWS.CodeGen.QuerySerializer

  test "serialize simple strings" do

    serialized = AWS.CodeGen.QuerySerializer.serialize(%{
      "Name1" => "abc",
      "Name2" => "xyz"
    }, %{
      "type" => "structure",
      "members" => %{
         "Name1" => %{
           "type" => "string"
         },
         "Name2" => %{
           "type" => "string"
         }
       }
    })

    assert "Name1=abc&Name2=xyz" = serialized

  end

  test "ignores null values" do

    serialized = AWS.CodeGen.QuerySerializer.serialize(%{
      "Name1" => "abc",
      "Name2" => nil,
      "Name3" => "xyz",
      "Name4" => nil,
    }, %{
      "type" => "structure",
      "members" => %{
         "Name1" => %{
           "type" => "string"
         },
         "Name2" => %{
           "type" => "string"
         },
         "Name3" => %{
           "type" => "string"
         },
         "Name4" => %{
            "type" => "string"
         },
       }
    })

    assert "Name1=abc&Name3=xyz" = serialized


  end

  test "nested structures" do

    serialized = AWS.CodeGen.QuerySerializer.serialize(%{
      "Name1" => %{
        "Name2" => %{
          "Name3" => "abc"
        }
      },
    }, %{
      "type" => "structure",
      "members" => %{
        "Name1" => %{
          "type" => "structure",
          "members" => %{
            "Name2" => %{
              "type" => "structure",
              "members" => %{
                "Name3" => %{
                  "type" => "string"
                }
              }
            },
           }
         },
       }
    })

    assert "Name1.Name2.Name3=abc" = serialized
  end


  test "nested structures with multiple properties" do

    serialized = AWS.CodeGen.QuerySerializer.serialize(%{
       "Name1" => %{
         "Name2" => "abc",
         "Name3" => "def"
       }
     }, %{
      "type" => "structure",
      "members" => %{
        "Name1" => %{
          "type" => "structure",
          "members" => %{
            "Name2" => %{
              "type" => "string",
            },
            "Name3" => %{
              "type" => "string",
            }
          }
         },
       }
    })

    assert "Name1.Name2=abc&Name1.Name3=def" = serialized
  end


  test "uses locationName when available" do

    serialized = AWS.CodeGen.QuerySerializer.serialize(%{
       "Name1" => %{
         "Name2" => "abc",
       }
     }, %{
      "type" => "structure",
      "members" => %{
        "Name1" => %{
          "type" => "structure",
          "locationName" => "Root",
          "members" => %{
            "Name2" => %{
              "type" => "string",
              "locationName" => "OtherName"

            }
          }
         },
       }
    })

    assert "Root.OtherName=abc" = serialized
  end

  describe "list" do

    test "numbers list items starting at index 1" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Name" => ["a", "b", "c"]
       }, %{
        "type" => "structure",
        "members" => %{
          "Name" => %{
            "type" => "list",
            "flattened" => true,
            "member" => %{
              "type" => "string",
            }
           }
         }
      })

      assert "Name.1=a&Name.2=b&Name.3=c" = serialized
    end


    test "uses list-member names instead of the list name" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Root" => %{"Name" => ["a", "b", "c"] }
       }, %{
        "type" => "structure",
        "members" => %{
          "Root" => %{
            "type" => "structure",
            "members" => %{
               "Name" => %{
                 "type" => "list",
                 "flattened" => true,
                 "member" => %{
                   "type" => "string",
                   "locationName" => "Alias"
                 }
                }
              }
            }
          }
      })

      assert "Root.Alias.1=a&Root.Alias.2=b&Root.Alias.3=c" = serialized
    end

    test "arrays into structure" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Name" => %{
           "Nested" => ["a", "b", "c"]
         }
       }, %{
        "type" => "structure",
        "members" => %{
          "Name" => %{
            "type" =>  "structure",
            "members" => %{
              "Nested" => %{
                "type" => "list",
                "flattened" => true,
                "member" => %{
                  "type" => "string"
                }
              }
            }
          }
        }
      })

      assert "Name.Nested.1=a&Name.Nested.2=b&Name.Nested.3=c" = serialized
    end

    test "supports lists of complex types" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Root" => [%{"A" => "a1", "B" => "b1"}, %{"A" => "a2", "B" => "b2"}]
       }, %{
        "type" => "structure",
        "members" => %{
          "Root" => %{
            "type" => "list",
            "flattened" => true,
            "member" => %{
              "type" => "structure",
              "members" => %{
                "A" => %{},
                "B" => %{}
              }
            }
          }
        }
      })

      assert "Root.1.A=a1&Root.1.B=b1&Root.2.A=a2&Root.2.B=b2" = serialized

    end


    test "append member name when array is non flat" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Root" => ["1", "2", "3"]
       }, %{
        "type" => "structure",
        "members" => %{
          "Root" => %{
            "type" => "list",
            "member" => %{
              "type" => "string"
            }
          }
        }
      })

      assert "Root.member.1=1&Root.member.2=2&Root.member.3=3" = serialized

    end


    test "observes both list name and list member name" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Root" => ["1"]
       }, %{
        "type" => "structure",
        "members" => %{
          "Root" => %{
            "type" => "list",
            "locationName" => "Toor",
            "member" => %{
              "type" => "string",
              "locationName" => "Poor"
            }
          }
        }
      })

      assert "Toor.Poor.1=1" = serialized

    end

    test "locationName works with deeply nested lists" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Root" => [%{"A" => "1"}]
       }, %{
        "type" => "structure",
        "members" => %{
          "Root" => %{
            "type" => "list",
            "locationName" => "Toor",
            "member" => %{
              "type" => "structure",
              "locationName" => "Poor",
              "members" => %{
                "A" => %{},
                "B" => %{}
              }
            }
          }
        }
      })

      assert "Toor.Poor.1.A=1" = serialized

    end
  end

  describe "Maps" do

    test "accepts a hash (object) of arbitrary key/value pairs" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Attributes" => %{"Color" => "red", "Size" => "large"}
       }, %{
        "type" => "structure",
        "members" => %{
          "Attributes" => %{
            "type" => "map",
            "flattened" => true,
            "key" => %{},
            "value" => %{}
          }
        }
      })

      assert "Attributes.1.key=Color&Attributes.1.value=red&Attributes.2.key=Size&Attributes.2.value=large" = serialized
    end

    test "adds .entry. to name" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Attributes" => %{"Color" => "red", "Size" => "large"}
       }, %{
        "type" => "structure",
        "members" => %{
          "Attributes" => %{
            "type" => "map",
            "key" => %{},
            "value" => %{}
          }
        }
      })

      assert "Attributes.entry.1.key=Color&Attributes.entry.1.value=red&Attributes.entry.2.key=Size&Attributes.entry.2.value=large" = serialized

    end

    test "applies member name traits" do

      serialized = AWS.CodeGen.QuerySerializer.serialize(%{
         "Attributes" => %{"Color" => "red", "Size" => "large"}
       }, %{
        "type" => "structure",
        "members" => %{
          "Attributes" => %{
            "type" => "map",
            "flattened" => true,
            "key" => %{
              "type" => "string",
              "locationName" => "OtherName"
            },
            "value" => %{
              "type" => "string",
              "locationName" => "OtherValue"
            }
          }
        }
      })

      assert "Attributes.1.OtherName=Color&Attributes.1.OtherValue=red&Attributes.2.OtherName=Size&Attributes.2.OtherValue=large" = serialized

    end

  end
end