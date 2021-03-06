#!/usr/bin/env bats -p

@test "delete linear pod" {
    run kubectl delete -f /files/linear.yaml
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pod \"volume-test\" deleted" ]
} 

@test "delete block pod" {
    run kubectl delete -f /files/block.yaml
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pod \"volume-test-block\" deleted" ]
} 

@test "simulate reboot" {
    run kubectl apply -f /files/simulate_reboot.yaml
    [ "$status" -eq 0 ]
} 

@test "deploy linear pod again" {
    run sleep 20
    run kubectl apply -f /files/linear.yaml
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pod/volume-test created" ]
} 

@test "deploy block pod again" {
    run kubectl apply -f /files/block.yaml
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "pod/volume-test-block created" ]
} 

@test "linear pod stays pending" {
    run kubectl wait -n ${PRTAG} --for=condition=ready pod/volume-test --timeout=20s
    run kubectl get pods -n ${PRTAG} volume-test -o jsonpath="{.metadata.name},{.status.phase}"
    [ "$status" -eq 0 ]
    [ "$output" = "volume-test,Pending" ]
}

@test "block pod stays pending" {
    run kubectl wait -n ${PRTAG} --for=condition=ready pod/volume-test-block --timeout=10s
    run kubectl get pods -n ${PRTAG} volume-test-block -o jsonpath="{.metadata.name},{.status.phase}"
    [ "$status" -eq 0 ]
    [ "$output" = "volume-test-block,Pending" ]
}
@test "start reviver" {
    run kubectl apply -f /files/reviver.yaml
    [ "$status" -eq 0 ]
} 

@test "linear pod running again" {
    run kubectl wait -n ${PRTAG} --for=condition=Available daemonset/csi-lvm-reviver-${PRTAG} --timeout=80s
    run kubectl wait -n ${PRTAG} --for=condition=ready pod/volume-test --timeout=60s
    run kubectl get pods -n ${PRTAG} volume-test -o jsonpath="{.metadata.name},{.status.phase}"
    [ "$status" -eq 0 ]
    [ "$output" = "volume-test,Running" ]
}

@test "block pod running again" {
    run kubectl wait -n ${PRTAG} --for=condition=ready pod/volume-test-block --timeout=80s
    run kubectl get pods -n ${PRTAG} volume-test-block -o jsonpath="{.metadata.name},{.status.phase}"
    [ "$status" -eq 0 ]
    [ "$output" = "volume-test-block,Running" ]
}

