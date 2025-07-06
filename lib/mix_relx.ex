defmodule Mix.Tasks.Relx do
  use Mix.Task

  @recursive true

  @impl true
  def run(_args) do
    Mix.Task.run("loadpaths")

    config = Mix.Project.config()
    name = config[:app]
    vsn = config[:version]

    # expand the config_src to substitute the version number
    if File.exists?("relx.config.src") do
      Mix.shell().print_app()

      substitutions = %{"RELEASE_VERSION" => vsn}
      envsubst("relx.config.src", "relx.config", fn key -> Map.get(substitutions, key, nil) end)
    end

    if File.exists?("relx.config") do
      Mix.shell().print_app()

      {:ok, relx_config} = :file.consult("relx.config")
      output_dir = Path.join(Mix.Project.build_path(), "rel")

      {:ok, _} = :relx.build_release(%{name: name, vsn: to_charlist(vsn)}, [output_dir: to_charlist(output_dir)] ++ relx_config)
    end

    :ok
  end

    defp envsubst(source, destination, getenv) do
    content = File.read!(source)

    # Get a list of the ${variables} that need replacing.
    vars = Regex.scan(~r/\${(.+)}/U, content)

    f = fn [p, v], c ->
      case getenv.(v) do
        nil ->
          warn("#{source}: env var #{v} not found")
          c

        r ->
          String.replace(c, p, r)
      end
    end

    content = List.foldl(vars, content, f)

    File.write!(destination, content)
  end

  defp warn(message) do
    Mix.shell().info([:yellow, message, :reset])
  end
end
