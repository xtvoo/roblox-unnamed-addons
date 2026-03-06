-- GripBoxDumper_Deps.lua
local function dumpDependencies(t, name)
    print("--- Dumping " .. name .. " Dependencies ---")
    if t and t.box and t.box.Dependencies then
        print("Found Dependencies in " .. name .. ".box:")
        for k, v in pairs(t.box.Dependencies) do
             print("  " .. tostring(k) .. ": " .. tostring(v))
        end
    else
        print("No Dependencies found in " .. name .. ".box")
    end
end

if getgenv().GripBox then
    dumpDependencies(getgenv().GripBox, "GripBox")
end

if getgenv().RotateGrip then
    dumpDependencies(getgenv().RotateGrip, "RotateGrip")
end

print("--- Checking Global Options ---")
if getgenv().Toggles then
   print("Checking Toggles for 'Grip' matches:")
   for k,v in pairs(getgenv().Toggles) do
       if string.find(string.lower(k), "grip") then
           print("  Toggle: " .. k)
       end
   end
end
if getgenv().Options then
   print("Checking Options for 'Grip' matches:")
   for k,v in pairs(getgenv().Options) do
       if string.find(string.lower(k), "grip") then
           print("  Option: " .. k)
       end
   end
end
