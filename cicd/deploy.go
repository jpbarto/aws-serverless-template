package main

import (
	"context"

	"dagger/shorturl/internal/dagger"
)

// Deploy installs the Helm chart from a Helm repository to a Kubernetes cluster
func (m *Shorturl) Deploy(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// Kubernetes config file content
	kubeconfig *dagger.Secret,
	// +optional
	// Helm chart repository URL (default: oci://ttl.sh)
	helmRepository string,
	// +optional
	// Release name (default: shorturl)
	releaseName string,
	// +optional
	// Kubernetes namespace (default: shorturl)
	namespace string,
	// +optional
	// Build as release candidate (appends -rc to version tag)
	releaseCandidate bool,
) (string, error) {
	output, err := dag.Container().
		From("alpine:latest").
		WithExec([]string{"echo", "this is the Deploy function"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return output, nil
}
