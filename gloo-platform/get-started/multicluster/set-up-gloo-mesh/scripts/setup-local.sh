#!/usr/bin/env bash


colima start --profile mgmt --cpu 4 --memory 8 --kubernetes
colima start --profile cluster1 --cpu 4 --memory 8 --kubernetes
colima start --profile cluster2 --cpu 4 --memory 8 --kubernetes

kubectl config rename-context colima-mgmt mgmt
kubectl config rename-context colima-cluster1 cluster1
kubectl config rename-context colima-cluster2 cluster2