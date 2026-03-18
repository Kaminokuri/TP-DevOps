#!/usr/bin/env python3

import os
import sys
from typing import Callable, List, Tuple

import docker
import requests


GRAFANA_USER = os.getenv("GRAFANA_USER", "admin")
GRAFANA_PASSWORD = os.getenv("GRAFANA_PASSWORD", "gitops2026")


def test_containers_running() -> bool:
    client = docker.from_env()
    required = ["prometheus", "grafana", "jenkins", "monitoring-app"]

    for name in required:
      try:
        container = client.containers.get(name)
        assert container.status == "running", f"{name} is not running"
        print(f"  {name} is running")
      except docker.errors.NotFound:
        print(f"  {name} not found")
        return False
      except Exception as exc:
        print(f"  {name} cannot be inspected: {exc}")
        return False
    return True


def test_services_health() -> bool:
    services = {
        "Prometheus": "http://localhost:9090/-/healthy",
        "Grafana": "http://localhost:3000/api/health",
        "Jenkins": "http://localhost:8080/login",
        "Monitoring App": "http://localhost:3001/health",
    }

    for service, url in services.items():
        try:
            response = requests.get(url, timeout=5)
            if response.status_code in (200, 401):
                print(f"  {service} is reachable")
            else:
                print(f"  {service} returned {response.status_code}")
                return False
        except requests.RequestException as exc:
            print(f"  {service} is unreachable: {exc}")
            return False

    return True


def test_prometheus_metrics() -> bool:
    try:
        response = requests.get(
            "http://localhost:9090/api/v1/query",
            params={"query": "up"},
            timeout=5,
        )
        payload = response.json()
        if payload.get("status") == "success":
            print("  Prometheus query endpoint works")
            return True
    except Exception as exc:
        print(f"  Failed to query Prometheus: {exc}")
        return False

    print("  Prometheus query endpoint returned unexpected data")
    return False


def test_grafana_datasources() -> bool:
    try:
        response = requests.get(
            "http://localhost:3000/api/datasources",
            auth=(GRAFANA_USER, GRAFANA_PASSWORD),
            timeout=5,
        )
        datasources = response.json()
        if any(item.get("type") == "prometheus" for item in datasources):
            print("  Grafana datasource provisioning is present")
            return True
    except Exception as exc:
        print(f"  Failed to inspect Grafana datasources: {exc}")
        return False

    print("  Grafana datasource provisioning is missing")
    return False


def main() -> int:
    tests: List[Tuple[str, Callable[[], bool]]] = [
        ("containers", test_containers_running),
        ("health", test_services_health),
        ("prometheus", test_prometheus_metrics),
        ("grafana", test_grafana_datasources),
    ]

    print("Running infrastructure tests...\n")
    results = []

    for name, test in tests:
        print(f"Running {name} test...")
        results.append(test())

    print("\n" + "=" * 40)
    if all(results):
        print("All tests passed.")
        return 0

    print("Some tests failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())

