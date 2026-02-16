#!/bin/bash
# Pod Security Standards Test Script
# This script automates testing of Pod Security Standards enforcement

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Pod Security Standards Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print test header
print_test_header() {
    echo -e "${YELLOW}Test: $1${NC}"
    echo "--------------------------------------"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    ((TESTS_PASSED++))
    echo ""
}

# Function to print failure
print_failure() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((TESTS_FAILED++))
    echo ""
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Not connected to a Kubernetes cluster${NC}"
    echo "Run: az aks get-credentials --resource-group <rg-name> --name <cluster-name>"
    exit 1
fi

echo -e "${GREEN}✓ kubectl configured${NC}"

# Check if Gatekeeper is running
if ! kubectl get pods -n gatekeeper-system &> /dev/null; then
    echo -e "${RED}Error: Gatekeeper system not found${NC}"
    echo "Azure Policy may not be enabled or synced yet (takes 5-10 minutes)"
    exit 1
fi

GATEKEEPER_PODS=$(kubectl get pods -n gatekeeper-system --no-headers 2>/dev/null | wc -l)
if [ "$GATEKEEPER_PODS" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No Gatekeeper pods found. Policies may not be enforced yet.${NC}"
fi

echo -e "${GREEN}✓ Gatekeeper system found (${GATEKEEPER_PODS} pods)${NC}"
echo ""

# Test 1: Non-Compliant Pod (Should Fail)
print_test_header "Non-Compliant Pod (Should be BLOCKED)"
if kubectl apply -f non-compliant-pod.yaml 2>&1 | grep -q "denied"; then
    print_success "Non-compliant pod was correctly BLOCKED by policy"
else
    print_failure "Non-compliant pod was NOT blocked (policy may not be active)"
fi

# Test 2: Compliant Pod (Should Succeed)
print_test_header "Compliant Pod (Should be ALLOWED)"
if kubectl apply -f compliant-pod.yaml &> /dev/null; then
    # Wait for pod to be ready
    if kubectl wait --for=condition=Ready pod/compliant-nginx --timeout=60s &> /dev/null; then
        print_success "Compliant pod was ALLOWED and is running"
    else
        print_failure "Compliant pod was allowed but failed to start"
    fi
else
    print_failure "Compliant pod was unexpectedly BLOCKED"
fi

# Test 3: Non-Compliant Deployment (Should Fail)
print_test_header "Non-Compliant Deployment (Should be BLOCKED)"
if kubectl apply -f non-compliant-deployment.yaml 2>&1 | grep -q "denied"; then
    print_success "Non-compliant deployment was correctly BLOCKED by policy"
else
    print_failure "Non-compliant deployment was NOT blocked"
fi

# Test 4: Compliant Deployment (Should Succeed)
print_test_header "Compliant Deployment (Should be ALLOWED)"
if kubectl apply -f compliant-deployment.yaml &> /dev/null; then
    # Wait for deployment to be ready
    if kubectl wait --for=condition=Available deployment/compliant-app --timeout=120s &> /dev/null; then
        READY_REPLICAS=$(kubectl get deployment compliant-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        print_success "Compliant deployment was ALLOWED and has $READY_REPLICAS replicas ready"
    else
        print_failure "Compliant deployment was allowed but not all replicas are ready"
    fi
else
    print_failure "Compliant deployment was unexpectedly BLOCKED"
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

# Show cluster resources
echo -e "${BLUE}Current Resources:${NC}"
echo "---"
kubectl get pods -o wide 2>/dev/null || echo "No pods found"
echo ""
kubectl get deployments -o wide 2>/dev/null || echo "No deployments found"
echo ""

# Cleanup prompt
echo -e "${YELLOW}Cleanup commands:${NC}"
echo "kubectl delete -f compliant-pod.yaml"
echo "kubectl delete -f compliant-deployment.yaml"
echo ""

# Check Policy State
echo -e "${BLUE}Policy Compliance Status:${NC}"
kubectl get constrainttemplates 2>/dev/null | head -n 10
echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Pod Security Standards are working correctly.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Check policy configuration and sync status.${NC}"
    exit 1
fi
