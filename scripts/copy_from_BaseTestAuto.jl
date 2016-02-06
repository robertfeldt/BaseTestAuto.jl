"""
Copy a specified range of lines from a julia file available at a URL
"""
function copy_lines_from(url::AbstractString, lineRanges::Vector{Tuple{Int64,Int64}})
  lines = lines_from_url(url)
  copied_lines = AbstractString[]
  for (s, e) in lineRanges
    for l in s:e
      push!(copied_lines, lines[l])
    end
  end
  copied_lines
end

function lines_from_url(url::AbstractString)
  filename = download(url)
  open(filename, "r") do fh
    return readlines(fh)
  end
end

BaseTestNextMainUrl = "https://raw.githubusercontent.com/JuliaCI/BaseTestNext.jl/master/src/BaseTestNext.jl"

open("src/parts_from_BaseTestNext.jl", "w") do fh
  println(fh, join(copy_lines_from(BaseTestNextMainUrl,
    Tuple{Int64,Int64}[
      (1, 2),
      (21, 296),
      (487, 529),
      (618, 796)
      ])))
end