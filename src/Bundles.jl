struct DSSBundle <: DSSObject
    project::DSSProject
    id::AbstractString
    DSSBundle(name::AbstractString, project::DSSProject=get_current_project()) = new(project, name)
end

macro bundle_str(str)
    createobject(DSSBundle, str)
end

export @bundle_str
export DSSBundle

get_details(bundle::DSSBundle) = request("GET", "projects/$(bundle.project.key)/bundles/exported/$(bundle.id)")

download_file(bundle::DSSBundle) = request("GET", "projects/$(bundle.project.key)/bundles/exported/$(bundle.id)/archive"; stream=true)

list_exported_bundles(project::DSSProject=get_current_project()) = request("GET", "projects/$(projectKey)/bundles/exported")["bundles"]
list_imported_bundles(project::DSSProject=get_current_project()) = request("GET", "projects/$(projectKey)/bundles/imported")["bundles"]

import_bundle_from_archive_file(path::AbstractString, project::DSSProject=get_current_project()) =
    request("POST", "projects/$(project.key)/bundles/imported/actions/importFromArchive"; params=Dict("archivePath" => path))

preload_a_bundle(bundle::DSSBundle) = uest("POST", "projects/$(bundle.project.key)/bundles/imported/$(bundle.id)/actions/preload")

activate_a_bundle(bundle::DSSBundle) = uest("POST", "projects/$(bundle.project.key)/bundles/imported/$(bundle.id)/actions/activate")

create_project_from_a_bundle(file::IO) = t_multipart("projectsFromBundle/", file)

create_project_from_a_bundle(archivePath::AbstractString) =
    request("POST", "projectsFromBundle/fromArchive"; params=Dict("archivePath" => archivePath))

create_a_new_bundle(name::AbstractString, project::DSSProject=get_current_project()) =
    request("PUT", "projects/$(project.key)/bundles/exported/$(name)")
