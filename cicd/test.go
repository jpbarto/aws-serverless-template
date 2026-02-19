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
	// Create a Node.js container with bash support
	testContainer := dag.Container().
		From("node:18-slim").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace")

	// Execute the run-unit-tests.sh script
	println("Running unit tests...")
	output, err := testContainer.
		WithExec([]string{"bash", "tests/run-unit-tests.sh"}).
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
	// Set defaults
	if targetHost == "" {
		targetHost = "localhost"
	}
	if targetPort == "" {
		targetPort = "8080"
	}

	// Construct the API URL
	apiUrl := "http://" + targetHost + ":" + targetPort

	// Create a container with curl and bash for running the integration tests
	testContainer := dag.Container().
		From("curlimages/curl:latest").
		WithExec([]string{"sh", "-c", "apk add --no-cache bash"}).
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace")

	// Execute the run-integration-tests.sh script
	println("Running integration tests against:", apiUrl)
	output, err := testContainer.
		WithExec([]string{"bash", "tests/run-integration-tests.sh", apiUrl}).
		Stdout(ctx)

	if err != nil {
		return "", err
	}

	return output, nil
}
