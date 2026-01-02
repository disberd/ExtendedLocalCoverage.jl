module ExampleExt

using Example

function Example.hello(n::Int)
    return "Hello number $(n)!"
end

end