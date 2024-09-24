module Config

using TOML

export read_config

function read_config(toml_file_path::String)::Dict
    return TOML.parsefile(toml_file_path)
end

end # Config module