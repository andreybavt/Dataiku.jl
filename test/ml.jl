try Dataiku.delete(project"TEST_JULIA_MODELS") catch end
project = Dataiku.create_project("TEST_JULIA_MODELS")

Dataiku.set_current_project(project)

body = Dict(
    "projectKey"   => project.key,
    "name"         => "test_dataset",
    "type"         => "Filesystem",
    "formatType"   => "csv",
    "managed"      => false,
    "params"       => Dict("connection" => "filesystem_root", "path" => joinpath(test_dir, "data", "part")),
    "formatParams" => Dict("style" => "excel", "separator"  => ",", "parseHeaderRow" => true),
    "schema"       => Dict("userModified" => false, "columns" => [
        Dict("name" => "A", "type" => "bigint"),
        Dict("name" => "B", "type" => "bigint"),
        Dict("name" => "C", "type" => "bigint")
    ]),
    "partitioning" => Dict(
        "filePathPattern" => "%{A}/.*",
        "dimensions" => [Dict("name" => "A", "type" => "value")]
    )
)

dataset = Dataiku.create_dataset(body)

analysis = Dataiku.create_analysis(dataset)
mltask = Dataiku.create_prediction_ml_task(dataset, :A)
Dataiku.create_prediction_ml_task(analysis, :A)

Dataiku.create_clustering_ml_task(dataset)
Dataiku.create_clustering_ml_task(analysis)

@test Dataiku.get_status(mltask)["guessing"] == false
@test Dataiku.guess(mltask)["predictionType"] == "REGRESSION"

@test Dataiku.list_analysis() |> length == 3
@test Dataiku.list_ml_tasks(analysis) |> length == 2
@test Dataiku.list_ml_tasks() |> length == 4

settings = Dataiku.get_settings(mltask)
@test settings["targetVariable"] == "A"
@test Dataiku.guess(mltask)["targetVariable"] == "A"
settings["preprocessing"]["per_feature"]["B"]["role"] = "INPUT"
settings["preprocessing"]["per_feature"]["B"]["missing_handling"] = "IMPUTE"
settings["preprocessing"]["per_feature"]["B"]["missing_impute_with"] = "MEDIAN"
settings["preprocessing"]["per_feature"]["B"]["numerical_handling"] = "REGULAR"
settings["preprocessing"]["per_feature"]["B"]["rescaling"] = "AVGSTD"

settings["preprocessing"]["per_feature"]["C"]["role"] = "INPUT"
settings["preprocessing"]["per_feature"]["C"]["missing_handling"] = "IMPUTE"
settings["preprocessing"]["per_feature"]["C"]["missing_impute_with"] = "MEDIAN"
settings["preprocessing"]["per_feature"]["C"]["numerical_handling"] = "REGULAR"
settings["preprocessing"]["per_feature"]["C"]["rescaling"] = "AVGSTD"

Dataiku.set_settings(mltask, settings)

trained_model_id = Dataiku.train(mltask)

@test length(trained_model_id) == 2

trained_model = DSSTrainedModel(mltask, 1, "RIDGE_REGRESSION")

@test Dataiku.get_snippet(trained_model)["algorithm"] == "RIDGE_REGRESSION"

saved_model = Dataiku.deploy_to_flow(trained_model)
@test Dataiku.redeploy_to_flow(trained_model, saved_model) == Dict("impactsDownstream" => false)

versions = Dataiku.list_versions(saved_model)
@test length(versions) == 2

version = DSSModelVersion(saved_model, versions[versions[1]["active"] ? 2 : 1])
@test Dataiku.set_active(version) == Dict("schemaChanged" => false)

version_user_meta = Dataiku.get_user_meta(version)
version_user_meta["description"] = "test description"
Dataiku.set_user_meta(version, version_user_meta)

@test Dataiku.get_user_meta(version)["description"] == "test description"

Dataiku.delete(saved_model)
Dataiku.delete(mltask)
Dataiku.delete(analysis)
Dataiku.delete(dataset)
Dataiku.delete(project)