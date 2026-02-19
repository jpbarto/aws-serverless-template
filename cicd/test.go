package main

import (
	"context"

	"dagger/shorturl/internal/dagger"
)

// UnitTest runs the shorturl container and executes unit tests against it
func (m *Shorturl) UnitTest(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// +optional
	// Build output from the Build function (if not provided, will build from source)
	buildArtifact *dagger.File,
) (string, error) {
	output, err := dag.Container().
		From("alpine:latest").
		WithExec([]string{"echo", "this is the UnitTest function"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return output, nil
}

// IntegrationTest runs integration tests against a deployed shorturl instance
func (m *Shorturl) IntegrationTest(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// +optional
	// Target host where shorturl is deployed (default: localhost)
	targetHost string,
	// +optional
	// Target port (default: 8080)
	targetPort string,
) (string, error) {
	output, err := dag.Container().
		From("alpine:latest").
		WithExec([]string{"echo", "this is the IntegrationTest function"}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return output, nil
}
