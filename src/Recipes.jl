struct DSSRecipe <: DSSObject
    project::DSSProject
    name::AbstractString
    DSSRecipe(name::AbstractString, project::DSSProject=get_current_project()) = new(project, name)
end

macro recipe_str(str)
    createobject(DSSRecipe, str)
end

export @recipe_str
export DSSRecipe

list_recipes(project::DSSProject=get_current_project()) = request("GET", "projects/$(project.key)/recipes/")

get_definition(recipe::DSSRecipe) = request("GET", "projects/$(recipe.project.key)/recipes/$(recipe.name)")

# Doesnt work with empty payloads?
set_definition(recipe::DSSRecipe, settings::AbstractDict) = request("PUT", "projects/$(recipe.project.key)/recipes/$(recipe.name)")

get_metadata(recipe::DSSRecipe) = request("GET", "projects/$(recipe.project.key)/recipes/$(recipe.name)/metadata")

set_metadata(recipe::DSSRecipe, metadata::AbstractDict) = request("PUT", "projects/$(recipe.project.key)/recipes/$(recipe.name)/metadata", metadata)


# should we add DSSRecipeCreator ?
function create_recipe(recipe::AbstractDict, project::DSSProject=get_current_project(); creationSettings::AbstractDict=Dict())
    recipe["projectKey"] = project.key
    body = Dict(
        "recipePrototype"  => recipe,
        "creationSettings" => creationSettings
    )
    request("POST", "projects/$(project.key)/recipes/", body)
    DSSRecipe(recipe["name"], project)
end

delete(recipe::DSSRecipe) = request("DELETE", "projects/$(recipe.project.key)/recipes/$(recipe.name)")

export create_recipe