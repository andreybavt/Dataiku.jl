"""
    get_definition(::DSSFolder)
    get_contents(::DSSFolder)
"""
struct DSSFolder <: DSSObject
    project::DSSProject
    id::AbstractString
    DSSFolder(id::AbstractString, project::DSSProject=get_current_project()) = new(project, id)
end

macro folder_str(str)
    createobject(DSSFolder, str)
end

export @folder_str
export DSSFolder

list_managed_folders(project::DSSProject=get_current_project()) = request("GET", "projects/$(projectKey)/managedfolders/")

function create_managed_folder(name::AbstractString, project::DSSProject=get_current_project();
    connection::AbstractString="filesystem_folders", path="$(project.key)/$(name)")
    body = Dict(
        "name"   => name,
        "params" => Dict(
            "connection" => connection,
            "path"       => path
        )
    )
    response = request("POST", "projects/$(project.key)/managedfolders/", body)
    DSSFolder(response["id"])
end

delete(folder::DSSFolder) = request("DELETE", "projects/$(folder.project.key)/managedfolders/$(folder.id)")

# get_definition might be better 
get_settings(folder::DSSFolder)= request("GET", "projects/$(folder.project.key)/managedfolders/$(folder.id)")


set_settings(folder::DSSFolder, settings::AbstractDict) =
    request("PUT", "projects/$(folder.project.key)/managedfolders/$(folder.id)", settings)

## Files

list_contents(folder::DSSFolder) = request("GET", "projects/$(folder.project.key)/managedfolders/$(folder.id)/contents/")


download_file(folder::DSSFolder, path::AbstractString) =
    request("GET", "projects/$(folder.project.key)/managedfolders/$(folder.id)/contents/$(path)"; stream=true)

upload_file(folder::DSSFolder, path::AbstractString, filename::AbstractString=path) =
    upload_file(folder, open(path; read=true), filename)

upload_file(folder::DSSFolder, file::IO, filename::AbstractString) =
    post_multipart("$(public_url)/projects/$(folder.project.key)/managedfolders/$(folder.id)/contents/", file, filename)

delete_file(folder::DSSFolder, path::AbstractString) =
    request("DELETE", "projects/$(folder.project.key)/managedfolders/$(folder.id)/contents/$(path)")


export list_contents
export download_file
export upload_file
export delete_file