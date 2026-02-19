package main

import (
	"context"

	"dagger/shorturl/internal/dagger"
)

// Build builds a multi-architecture Docker image and exports it as an OCI tarball
func (m *Shorturl) Build(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// +optional
	// Whether to build as release candidate (appends -rc to version)
	releaseCandidate bool,
) (*dagger.File, error) {
	output, err := dag.Container().
		From("alpine:latest").
		WithExec([]string{"echo", "This is the Build function"}).
		Stdout(ctx)

	if err != nil {
		return nil, err
	}

	println(output)

	return dag.Container().From("alpine:latest").File("/etc/hostname"), nil
}
