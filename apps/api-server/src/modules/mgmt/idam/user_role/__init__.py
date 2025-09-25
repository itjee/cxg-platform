from .model import UserRole
from .router import router
from .schemas import (
    UserRoleCreate,
    UserRoleCreateRequest,
    UserRoleRead,
    UserRoleResponse,
    UserRoleUpdate,
    UserRoleUpdateRequest,
)
from .service import UserRoleService

__all__ = [
    # Model
    "UserRole",
    # Router
    "router",
    # Schemas - existing Request/Response classes
    "UserRoleCreateRequest",
    "UserRoleResponse",
    "UserRoleUpdateRequest",
    # Schemas - new PascalCase classes
    "UserRoleCreate",
    "UserRoleRead",
    "UserRoleUpdate",
    # Service
    "UserRoleService",
]
