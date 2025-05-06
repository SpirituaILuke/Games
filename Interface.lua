
local typeface = {  };
do
    typeface.Incompatible	= function() typeface.Denied = true end
    isfile                  = isfile or typeface.Incompatible()
    isfolder                = isfolder or typeface.Incompatible()
    writefile               = writefile or typeface.Incompatible()
    makefolder              = makefolder or typeface.Incompatible()
    getcustomasset 			= getcustomasset or typeface.Incompatible()
end

local Http = cloneref and cloneref(game:GetService 'HttpService') or game:GetService 'HttpService'
--
typeface.typefaces = {  }
typeface.WeightNum = { 
	["Thin"] = 100,

	["ExtraLight"] = 200, 
	["UltraLight"] = 200,

	["Light"] = 300,

	["Normal"] = 400,
	["Regular"] = 400,

	["Medium"] = 500,

	["SemiBold"] = 600,
	["DemiBold"] = 600,

	["Bold"] = 700,

	["ExtraBold"] = 800,

	["UltraBold"] = 900,
	["Heavy"] = 900
};

-- funcs
function typeface:register(Path, Asset)
	Asset = Asset or {}

    Asset.weight = Asset.weight or "Regular"
    Asset.style = Asset.style or "Normal"

    if not Asset.link or not Asset.name then 
        return
    end

	if typeface.Denied then 
        return
    end

	local Directory = `{ Path or "" }/{ Asset.name }`

    local Weight = typeface.WeightNum[Asset.weight] == 400 and "" or Asset.weight
    local Style = string.lower(Asset.style) == "normal" and "" or Asset.style
	local Name = `{ Asset.name }{ Weight }{ Style }`

    if not isfolder(Directory) then
        makefolder(Directory)
    end

    if not isfile(`{ Directory }/{ Name }.font`) then
		writefile(`{ Directory }/{ Name }.font`, game:HttpGet(Asset.link))
	end

    if not isfile(`{ Directory }/{ Asset.name }Families.json`) then 
		local Data = { 
			name = `{ Asset.weight } { Asset.style }`,
			weight = typeface.WeightNum[Asset.weight] or typeface.WeightNum[string.gsub(Asset.weight, "%s+", "")],
			style = string.lower(Asset.style),
			assetId = getcustomasset(`{ Directory }/{ Name }.font`)
		}

		local JSONFile = Http:JSONEncode({ name = Name, faces = { Data } })
		writefile(`{ Directory }/{ Asset.name }Families.json`, JSONFile)
	else
		local Registered = false
        local JSONFile = Http:JSONDecode(readfile(`{ Directory }/{ Asset.name }Families.json`))
		local Data = { 
            name = `{ Asset.weight } { Asset.style }`,
            weight = typeface.WeightNum[Asset.weight] or typeface.WeightNum[string.gsub(Asset.weight, "%s+", "")],
            style = string.lower(Asset.style),
            assetId = getcustomasset(`{ Directory }/{ Name }.font`)
		}

        for _, v in JSONFile.faces do
            if v.name == Data.name then Registered = true end
        end

        if not Registered then
            table.insert(JSONFile.faces, Data)
            JSONFile = Http:JSONEncode(JSONFile)
            writefile(`{ Directory }/{ Asset.name }Families.json`, JSONFile)
        end
        
	end

	typeface.typefaces[Name] = typeface.typefaces[Name] or Font.new(getcustomasset(`{ Directory }/{ Asset.name }Families.json`))
    return typeface.typefaces[Name]
end

return typeface;
