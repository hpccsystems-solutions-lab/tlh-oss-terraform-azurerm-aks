function SoftCopy (from_table, from_key, to_table, to_key)
  -- Soft copy (no overwrite). Copy content of to_key to from_key if to_key is not existing
  if to_table[tostring(to_key)]==nil
  then
    to_table[tostring(to_key)] = from_table[tostring(from_key)]
  end
end

function Remove (table,key)
  -- Remove the value of key by setting value to nil
  table[tostring(key)] = nil
end

function Add (table,key,val)
  -- Add key into table with value of val
  table[tostring(key)] = val
end

function HostRecordModifier(tag, timestamp, record)
  -- Soft copy (no overwrite) existing labels to desired labels and add namespace label
  SoftCopy(record,"hostname", record, "node")
  SoftCopy(record,"systemd_unit", record, "app")
  Add(record,"namespace","_")
  return 1, timestamp, record
end

function KubeRecordModifier(tag, timestamp, record)
  -- Shift kubernetes labels to top level and prefix with "kubernetes_"
  if record.kubernetes ~= nil then
    local tmp = {}
    for key,value in pairs(record.kubernetes) do tmp["kubernetes_"..key] = value end
    for key,value in pairs(tmp) do record[key] = value end
  end

  -- Shift "kubernetes_labels" labels to "labels. Creates labels object if doesnt exist, copies object over and then removes the old object
  if record.kubernetes_labels ~= nil then
    if record.labels==nil then record.labels = {} end
    for key,value in pairs(record.kubernetes_labels) do record.labels[key] = value end
  end

  -- Shift "kubernetes_annotations" labels to "annotations". Creates annotations object if doesnt exist, copies object over and then removes the old object
  if record.kubernetes_annotations ~= nil then
    if record.annotations==nil then record.annotations = {} end
    for key,value in pairs(record.kubernetes_annotations) do record.annotations[key] = value end
  end

  -- Soft copy (no overwrite) existing labels to desired labels
  SoftCopy(record,"kubernetes_host",record,"node")
  SoftCopy(record,"kubernetes_namespace_name",record,"namespace")
  SoftCopy(record,"kubernetes_pod_name",record,"pod")
  SoftCopy(record,"kubernetes_container_name",record,"container")
  SoftCopy(record,"kubernetes_container_hash",record,"containerHash")
  SoftCopy(record,"kubernetes_container_image",record,"containerImage")
  SoftCopy(record.kubernetes_labels,"app.kubernetes.io/name",record,"app")
  SoftCopy(record.kubernetes_labels,"app",record,"app")
  SoftCopy(record,"kubernetes_pod_name",record,"app")
  SoftCopy(record.kubernetes_labels,"app.kubernetes.io/instance",record,"instance")
  SoftCopy(record,"kubernetes_namespace_name",record,"instance")
  SoftCopy(record.kubernetes_labels,"app.kubernetes.io/component",record,"component")
  SoftCopy(record.kubernetes_labels,"app.kubernetes.io/part-of",record,"partOf")
  SoftCopy(record.kubernetes_labels,"app.kubernetes.io/version",record,"version")

  -- Remove labels
  Remove(record,"_p")
  Remove(record,"stream")

  -- Remove labels containing "kubernetes" or "kubernetes_"
  Remove(record,"kubernetes")
  for key in pairs(record) do
    if string.match(tostring(key),'^kubernetes_(.*)') then
      Remove(record,key)
    end
  end

  return 1, timestamp, record
end
