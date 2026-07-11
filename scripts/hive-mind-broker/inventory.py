import yaml
import os
import logging
from pathlib import Path

logger = logging.getLogger(__name__)


class Inventory:
    def __init__(self, filepath=None):
        # Default resolves relative to THIS file, not the process's current working
        # directory — a bare relative "inventory.yaml" only loads correctly when the
        # cwd happens to be this directory (e.g. `uvicorn app:app` run from here), and
        # silently loads zero routers otherwise (as when pytest is invoked from the
        # repo root, which is exactly how CI runs it).
        self.filepath = filepath or str(Path(__file__).resolve().parent / "inventory.yaml")
        self.routers = []
        self.load()

    def load(self):
        if not os.path.exists(self.filepath):
            logger.warning("Inventory file not found: %s", self.filepath)
            return

        with open(self.filepath, 'r') as f:
            data = yaml.safe_load(f)
            if data and 'routers' in data:
                self.routers = data['routers']

        logger.info("Loaded %d routers from inventory.", len(self.routers))

    def get_routers(self):
        return self.routers

    def get_routers_for_tenant(self, tenant):
        """Return only the routers belonging to *tenant*.

        Tenant isolation: a block must never reach another tenant's router. An
        unknown tenant — or routers with no `tenant` field — yields an empty list,
        so the caller dispatches to nothing rather than broadcasting.
        """
        if not tenant:
            return []
        return [r for r in self.routers if r.get("tenant") == tenant]

# Quick test if run directly
if __name__ == "__main__":
    inv = Inventory()
    for r in inv.get_routers():
        print(f"Router ID: {r['id']}, Tenant: {r.get('tenant')}, IP: {r['ip_address']}")
