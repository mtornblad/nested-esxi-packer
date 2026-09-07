import sys
import os
import hashlib
import tarfile

def inject_ovf(ovf_path):
    with open(ovf_path, 'r', encoding='utf-8') as f:
        ovf_content = f.read()

    # 1. Injicera ExtraConfig före </VirtualHardwareSection>
    extra_config = """
      <vmw:ExtraConfig ovf:required="false" vmw:key="disk.enableuuid" vmw:value="TRUE"/>
      <vmw:ExtraConfig ovf:required="false" vmw:key="msg.autoanswer" vmw:value="true"/>
      <vmw:ExtraConfig ovf:required="false" vmw:key="vhv.enable" vmw:value="TRUE"/>
    """
    ovf_content = ovf_content.replace('</VirtualHardwareSection>', f'{extra_config}\n    </VirtualHardwareSection>')

    # 2. Injicera vApp ProductSection före </VirtualSystem>
    vapp_config = """
      <ProductSection ovf:required="false">
        <Info>Nested ESXi Appliance Properties</Info>
        <Product>Nested ESXi</Product>
        <Property ovf:key="guestinfo.hostname" ovf:type="string" ovf:userConfigurable="true" ovf:value="">
            <Label>System Hostname</Label>
        </Property>
        <Property ovf:key="guestinfo.ipaddress" ovf:type="string" ovf:userConfigurable="true" ovf:value="">
            <Label>IP Address</Label>
        </Property>
        <Property ovf:key="guestinfo.password" ovf:type="string" ovf:password="true" ovf:userConfigurable="true" ovf:value="">
            <Label>Root Password</Label>
        </Property>
      </ProductSection>
    """
    ovf_content = ovf_content.replace('</VirtualSystem>', f'{vapp_config}\n  </VirtualSystem>')

    with open(ovf_path, 'w', encoding='utf-8') as f:
        f.write(ovf_content)
    
    return ovf_path

def create_manifest_and_ova(ovf_path):
    base_dir = os.path.dirname(ovf_path)
    ovf_name = os.path.basename(ovf_path)
    vmdk_name = ovf_name.replace('.ovf', '-disk-0.vmdk')
    mf_name = ovf_name.replace('.ovf', '.mf')
    ova_name = ovf_name.replace('.ovf', '.ova')

    # Skapa hash för OVF och VMDK
    def sha256_file(filepath):
        sha256 = hashlib.sha256()
        with open(filepath, 'rb') as f:
            for block in iter(lambda: f.read(65536), b''):
                sha256.update(block)
        return sha256.hexdigest()

    ovf_hash = sha256_file(ovf_path)
    vmdk_hash = sha256_file(os.path.join(base_dir, vmdk_name))

    # Skriv .mf-fil
    mf_path = os.path.join(base_dir, mf_name)
    with open(mf_path, 'w') as f:
        f.write(f"SHA256({ovf_name})= {ovf_hash}\n")
        f.write(f"SHA256({vmdk_name})= {vmdk_hash}\n")

    # Bygg OVA
    with tarfile.open(os.path.join(base_dir, ova_name), 'w') as tar:
        tar.add(ovf_path, arcname=ovf_name)
        tar.add(mf_path, arcname=mf_name)
        tar.add(os.path.join(base_dir, vmdk_name), arcname=vmdk_name)

if __name__ == "__main__":
    ovf_file = sys.argv[1]
    inject_ovf(ovf_file)
    create_manifest_and_ova(ovf_file)
    print(f"Genererade {ovf_file.replace('.ovf', '.ova')} framgångsrikt.")