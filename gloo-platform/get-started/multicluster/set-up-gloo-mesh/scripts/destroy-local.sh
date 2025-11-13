#!/usr/bin/env bash


colima delete --profile mgmt --force
colima delete --profile cluster1 --force
colima delete --profile cluster2 --force

kubectl config delete-context mgmt
kubectl config delete-context cluster1
kubectl config delete-context cluster2
