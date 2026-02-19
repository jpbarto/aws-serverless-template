package main

import (
	"context"

	"dagger/shorturl/internal/dagger"
)

// Build validates and builds the NodeJS Lambda function
func (m *Shorturl) Build(
	ctx context.Context,
	// Source directory containing the project
	source *dagger.Directory,
	// +optional
	// Whether to build as release candidate (appends -rc to version)
	releaseCandidate bool,
) (*dagger.File, error) {
	// Create a Node.js container for building and validating
	nodeContainer := dag.Container().
		From("node:18-slim").
		WithDirectory("/workspace", source).
		WithWorkdir("/workspace/src/lambda")

	// Install dependencies
	println("Installing npm dependencies...")
	nodeContainer = nodeContainer.
		WithExec([]string{"npm", "install"})

	// Validate syntax by checking for syntax errors
	println("Validating JavaScript syntax...")
	_, err := nodeContainer.
		WithExec([]string{"node", "--check", "index.js"}).
		Stdout(ctx)

	if err != nil {
		return nil, err
	}

	// Run tests to ensure functionality
	println("Running tests to validate functionality...")
	testOutput, err := nodeContainer.
		WithExec([]string{"npm", "test"}).
		Stdout(ctx)

	if err != nil {
		return nil, err
	}

	println(testOutput)
	println("Build validation successful!")

	// Create a tarball of just the Lambda function directory with dependencies
	return dag.Container().
		From("alpine:latest").
		WithDirectory("/lambda", nodeContainer.Directory("/workspace/src/lambda")).
		WithWorkdir("/").
		WithExec([]string{"tar", "czf", "/lambda.tar.gz", "lambda"}).
		File("/lambda.tar.gz"), nil
}
