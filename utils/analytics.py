import os
import uproot

def analyze_root_file(output_file):
    if os.path.exists(output_file):
        file_size = os.path.getsize(output_file)
        print(f"📁 File size: {file_size:,} bytes ({file_size / (1024**2):.2f} MB)")
        
        try:
            # Open ROOT file with uproot
            print("\n🌿 Opening ROOT file with uproot...")
            root_file = uproot.open(output_file)
            print("📋 File contents:")
            print("=" * 50)
            
            # Debug: Show ALL keys and their types
            print("🔍 ALL OBJECTS IN ROOT FILE:")
            for key in root_file.keys():
                obj = root_file[key]
                obj_type = type(obj).__name__
                print(f"  📄 {key} → {obj_type}")
                # Also try to see if it has keys (indicating it's a tree/directory)
                try:
                    if hasattr(obj, 'keys'):
                        sub_keys = list(obj.keys())
                        print(f"      └─ Has {len(sub_keys)} items: {sub_keys[:10]}{'...' if len(sub_keys) > 10 else ''}")
                except:
                    pass
            
            print("\n" + "=" * 50)
            
            # Look for MuonSystem tree - try exact match first
            muon_tree = None
            muon_tree_key = None
            
            # First try exact match
            if 'MuonSystem' in root_file:
                muon_tree = root_file['MuonSystem']
                muon_tree_key = 'MuonSystem'
                print(f"✅ Found exact match: {muon_tree_key}")
            else:
                # Then try case-insensitive search
                for key in root_file.keys():
                    if 'MuonSystem' in key or 'muon' in key.lower():
                        muon_tree = root_file[key]
                        muon_tree_key = key
                        print(f"✅ Found tree: {key}")
                        break
            
            if muon_tree is None:
                print("❌ No MuonSystem tree found with any variation")
                print("Let's try accessing it directly to see what happens...")
                try:
                    test_tree = root_file["MuonSystem"]
                    print("✅ Direct access worked! The tree exists.")
                    muon_tree = test_tree
                    muon_tree_key = "MuonSystem"
                except Exception as e:
                    print(f"❌ Direct access failed: {e}")
            
            if muon_tree is not None:
                print(f"\n🔍 Analyzing tree: {muon_tree_key}")
                print(f"Tree type: {type(muon_tree).__name__}")
                
                try:
                    branches = muon_tree.keys()
                    print(f"📈 Tree has {len(branches)} branches")
                    
                    # Look for the specific branches we care about
                    target_branches = ['cscRechitsClusterId', 'dtRechitsClusterId']
                    found_branches = []
                    
                    for branch_name in target_branches:
                        if branch_name in branches:
                            found_branches.append(branch_name)
                            print(f"✅ Found branch: {branch_name}")
                        else:
                            print(f"❌ Branch not found: {branch_name}")
                    
                    # If we found any target branches, show their values
                    if found_branches:
                        print(f"\n📊 Reading data from {len(found_branches)} branches...")
                        
                        for branch_name in found_branches:
                            print(f"\n🌿 Branch: {branch_name}")
                            print("=" * 60)
                            
                            try:
                                                            # Read the branch data
                                branch_data = muon_tree[branch_name].array()  # type: ignore
                                print(f"📈 Total entries: {len(branch_data)}")
                                
                                # Show first few entries and their structure
                                print(f"\n📋 First 1000 entries:")
                                for i in range(min(1000, len(branch_data))):
                                    entry = branch_data[i]
                                    if hasattr(entry, '__len__') and not isinstance(entry, str):
                                        # It's an array-like entry
                                        print(f"  Entry {i:3d}: {list(entry)} (length: {len(entry)})")
                                    else:
                                        # It's a single value
                                        print(f"  Entry {i:3d}: {entry}")
                                
                                # Show some statistics
                                print(f"\n📊 Statistics for {branch_name}:")
                                if len(branch_data) > 0:
                                    # Flatten all values to analyze
                                    all_values = []
                                    for entry in branch_data:
                                        if hasattr(entry, '__len__') and not isinstance(entry, str):
                                            all_values.extend(list(entry))
                                        else:
                                            all_values.append(entry)
                                    
                                    if all_values:
                                        unique_values = set(all_values)
                                        print(f"  Total individual values: {len(all_values)}")
                                        print(f"  Unique values: {len(unique_values)}")
                                        print(f"  Value range: {min(all_values)} to {max(all_values)}")
                                        print(f"  Most common values: {sorted(list(unique_values))[:20]}")
                                    else:
                                        print("  No values found")
                                
                            except Exception as e:
                                print(f"❌ Error reading branch {branch_name}: {e}")
                    else:
                        print(f"\n❌ None of the target branches found!")
                        print(f"📋 Available branches containing 'cluster' or 'id':")
                        relevant_branches = [b for b in branches if 'cluster' in b.lower() or 'id' in b.lower()]
                        for branch in relevant_branches:
                            print(f"  🌿 {branch}")
                            
                except Exception as e:
                    print(f"❌ Error analyzing tree: {e}")
                    
        except Exception as e:
            print(f"❌ Error opening ROOT file with uproot: {e}")
            print("Make sure uproot is installed: pip install uproot")
            
    else:
        print(f"❌ File not found: {output_file}")



    root_file = uproot.open(output_file)
    tree = root_file["MuonSystem"]

    # Get the cluster ID data
    csc_cluster_data = tree["cscRechitsClusterId"].array(library="np")
    dt_cluster_data = tree["dtRechitsClusterId"].array(library="np")

    # Count number of rechits in each event
    csc_rechit_counts = [len(entry) for entry in csc_cluster_data]
    dt_rechit_counts = [len(entry) for entry in dt_cluster_data]

    # Display statistics
    print("📈 CSC Rechits per Event:")
    print(f"  Total events: {len(csc_rechit_counts)}")
    print(f"  Events with rechits: {sum(1 for count in csc_rechit_counts if count > 0)}")
    print(f"  Events with no rechits: {sum(1 for count in csc_rechit_counts if count == 0)}")
    print(f"  Max rechits in single event: {max(csc_rechit_counts)}")
    print(f"  Average rechits per event: {sum(csc_rechit_counts) / len(csc_rechit_counts):.2f}")
    print(f"  Average rechits per non-empty event: {sum(csc_rechit_counts) / max(1, sum(1 for count in csc_rechit_counts if count > 0)):.2f}")

    print("\n📈 DT Rechits per Event:")
    print(f"  Total events: {len(dt_rechit_counts)}")
    print(f"  Events with rechits: {sum(1 for count in dt_rechit_counts if count > 0)}")
    print(f"  Events with no rechits: {sum(1 for count in dt_rechit_counts if count == 0)}")
    print(f"  Max rechits in single event: {max(dt_rechit_counts)}")
    print(f"  Average rechits per event: {sum(dt_rechit_counts) / len(dt_rechit_counts):.2f}")
    print(f"  Average rechits per non-empty event: {sum(dt_rechit_counts) / max(1, sum(1 for count in dt_rechit_counts if count > 0)):.2f}")

    print("\n📋 First 1000 events - rechit counts:")
    print("Event    CSC    DT")
    print("-" * 20)
    for i in range(min(1000, len(csc_rechit_counts))):
        print(f"{i:5d}    {csc_rechit_counts[i]:3d}    {dt_rechit_counts[i]:2d}")

    # Find events with most rechits
    print(f"\n🔍 Events with most CSC rechits:")
    csc_with_counts = [(i, count) for i, count in enumerate(csc_rechit_counts) if count > 0]
    csc_with_counts.sort(key=lambda x: x[1], reverse=True)
    for i, (event_idx, count) in enumerate(csc_with_counts[:5]):
        print(f"  Event {event_idx}: {count} CSC rechits")

    print(f"\n🔍 Events with most DT rechits:")
    dt_with_counts = [(i, count) for i, count in enumerate(dt_rechit_counts) if count > 0]
    dt_with_counts.sort(key=lambda x: x[1], reverse=True)
    for i, (event_idx, count) in enumerate(dt_with_counts[:5]):
        print(f"  Event {event_idx}: {count} DT rechits")

    # Show distribution of rechit counts
    print(f"\n📊 CSC Rechit Count Distribution:")
    from collections import Counter
    csc_count_dist = Counter(csc_rechit_counts)
    for count in sorted(csc_count_dist.keys())[:10]:  # Show first 10 different counts
        print(f"  {count:3d} rechits: {csc_count_dist[count]:4d} events")
    if len(csc_count_dist) > 10:
        print(f"  ... and {len(csc_count_dist) - 10} more different counts")

    print(f"\n📊 DT Rechit Count Distribution:")
    dt_count_dist = Counter(dt_rechit_counts)
    for count in sorted(dt_count_dist.keys()):
        print(f"  {count:3d} rechits: {dt_count_dist[count]:4d} events")


    root_file = uproot.open(output_file)
    tree = root_file["MuonSystem"]

    # Get the cluster ID data
    csc_cluster_data = tree["cscRechitsClusterId"].array(library="np")
    dt_cluster_data = tree["dtRechitsClusterId"].array(library="np")

    # Count number of rechits in each event
    csc_rechit_counts = [len(entry) for entry in csc_cluster_data]
    dt_rechit_counts = [len(entry) for entry in dt_cluster_data]

    # Calculate total numbers across all events
    total_csc_rechits = sum(csc_rechit_counts)
    total_dt_rechits = sum(dt_rechit_counts)

    print("🔢 TOTAL NUMBER OF INDIVIDUAL VALUES:")
    print("=" * 50)
    print(f"📊 CSC Branch (cscRechitsClusterId):")
    print(f"  Total individual cluster IDs: {total_csc_rechits:,}")
    print(f"📊 DT Branch (dtRechitsClusterId):")
    print(f"  Total individual cluster IDs: {total_dt_rechits:,}")
    print(f"📊 Combined:")
    print(f"  Grand total across both branches: {total_csc_rechits + total_dt_rechits:,}")

    print(f"\n📈 Verification (should match statistics from previous output):")
    print(f"  CSC: {len(csc_rechit_counts)} events × {total_csc_rechits/len(csc_rechit_counts):.2f} avg = {total_csc_rechits} total")
    print(f"  DT:  {len(dt_rechit_counts)} events × {total_dt_rechits/len(dt_rechit_counts):.2f} avg = {total_dt_rechits} total")

    print(f"\n🎯 What these numbers represent:")
    print(f"  - Each number = one rechit (detector hit) with its cluster assignment")
    print(f"  - CSC: {total_csc_rechits} individual rechits across all {len(csc_rechit_counts)} events")
    print(f"  - DT: {total_dt_rechits} individual rechits across all {len(dt_rechit_counts)} events")
