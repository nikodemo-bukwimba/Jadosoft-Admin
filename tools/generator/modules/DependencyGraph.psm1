# ============================================================
# DependencyGraph.psm1
# Builds a cross-feature dependency graph from all configs.
# Detects circular dependencies via DFS.
# Returns topological generation order.
# ============================================================

function Build-DependencyGraph {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configs  # featureName → config object
    )

    # Build adjacency list: feature → list of features it depends on
    $adjacency = @{}
    foreach ($name in $Configs.Keys) {
        $adjacency[$name] = [System.Collections.Generic.List[string]]::new()
    }

    foreach ($name in $Configs.Keys) {
        $config = $Configs[$name]
        if (-not $config.entities) { continue }

        foreach ($eName in $config.entities.PSObject.Properties.Name) {
            $entity = $config.entities.$eName
            if (-not $entity.relationships) { continue }

            foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
                $rel = $entity.relationships.$rName
                if ($rel.type -eq 'belongsTo' -and $rel.feature) {
                    $dep = $rel.feature
                    if ($dep -ne $name -and $dep -notin $adjacency[$name]) {
                        $adjacency[$name].Add($dep)
                    }
                }
            }
        }
    }

    # Detect circular dependencies via DFS
    $visited = @{}
    $inStack = @{}
    $cycles = [System.Collections.Generic.List[string]]::new()

    # Script block used instead of a nested function to avoid module-scope leakage.
    # Must be called with the call operator: & $findCycles <node> <path>
    # Note: $visited, $inStack, $cycles, $adjacency are captured from the enclosing scope.
    $findCycles = $null  # forward-declare so the recursive call inside can resolve it
    $findCycles = {
        param([string]$node, [System.Collections.Generic.List[string]]$path)

        $visited[$node] = $true
        $inStack[$node] = $true

        foreach ($neighbor in $adjacency[$node]) {
            if (-not $visited.ContainsKey($neighbor)) {
                $path.Add($neighbor)
                & $findCycles $neighbor $path
                $path.RemoveAt($path.Count - 1)
            }
            elseif ($inStack[$neighbor]) {
                # Found cycle — reconstruct the cycle path
                $cycleStart = $path.IndexOf($neighbor)
                $cyclePath = $path[$cycleStart..($path.Count - 1)]
                $cyclePath += $neighbor
                $cycles.Add(($cyclePath -join ' → '))
            }
        }

        $inStack[$node] = $false
    }

    foreach ($name in $Configs.Keys) {
        if (-not $visited.ContainsKey($name)) {
            $path = [System.Collections.Generic.List[string]]::new()
            $path.Add($name)
            & $findCycles $name $path
        }
    }

    # ── Topological sort (Kahn's algorithm) ───────────────────
    # in_degree[n] = number of dependencies n has (must be satisfied before n is generated).
    # Leaf nodes (no dependencies) enter the queue first.
    $inDegree = @{}
    foreach ($name in $Configs.Keys) {
        $inDegree[$name] = ($adjacency[$name] | Select-Object -Unique).Count
    }

    # Reverse adjacency: for each dependency, which features are waiting on it?
    $reverseAdj = @{}
    foreach ($name in $Configs.Keys) { $reverseAdj[$name] = [System.Collections.Generic.List[string]]::new() }
    foreach ($name in $Configs.Keys) {
        foreach ($dep in ($adjacency[$name] | Select-Object -Unique)) {
            if ($reverseAdj.ContainsKey($dep)) {
                $reverseAdj[$dep].Add($name)
            }
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($name in $Configs.Keys) {
        if ($inDegree[$name] -eq 0) { $queue.Enqueue($name) }
    }

    $sorted = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count -gt 0) {
        $node = $queue.Dequeue()
        $sorted.Add($node)
        foreach ($dependent in $reverseAdj[$node]) {
            $inDegree[$dependent]--
            if ($inDegree[$dependent] -eq 0) { $queue.Enqueue($dependent) }
        }
    }

    # ── Dependency maps ───────────────────────────────────────
    # featureName → list of external features it depends on
    $dependencies = @{}
    foreach ($name in $Configs.Keys) {
        $dependencies[$name] = @($adjacency[$name])
    }

    # featureName → list of features that depend on it
    $dependents = @{}
    foreach ($name in $Configs.Keys) { $dependents[$name] = @() }
    foreach ($name in $Configs.Keys) {
        foreach ($dep in $adjacency[$name]) {
            $dependents[$dep] += $name
        }
    }

    # ── Collect all belongsTo relationship details for provider generation ──
    $externalRelationships = @{}
    foreach ($name in $Configs.Keys) {
        $externalRelationships[$name] = [System.Collections.Generic.List[hashtable]]::new()
        $config = $Configs[$name]
        if (-not $config.entities) { continue }

        foreach ($eName in $config.entities.PSObject.Properties.Name) {
            $entity = $config.entities.$eName
            if (-not $entity.relationships) { continue }

            foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
                $rel = $entity.relationships.$rName
                if ($rel.type -eq 'belongsTo' -and $rel.feature) {
                    $externalRelationships[$name].Add(@{
                            RelationshipName = $rName
                            EntityName       = $eName
                            ExternalEntity   = $rel.entity
                            ExternalFeature  = $rel.feature
                            ForeignKey       = $rel.foreignKey
                            DisplayField     = $rel.displayField
                            Searchable       = $rel.searchable -eq $true
                        })
                }
            }
        }
    }

    return @{
        Adjacency             = $adjacency
        Dependencies          = $dependencies
        Dependents            = $dependents
        CircularDependencies  = $cycles
        TopologicalOrder      = $sorted
        ExternalRelationships = $externalRelationships
    }
}

Export-ModuleMember -Function Build-DependencyGraph