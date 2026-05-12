from fastapi import HTTPException

def can_access_branch(user, branch_id: int):
    if user["role"] == "head_coach":
        return
    if user.get("branch_id") is not None and int(user["branch_id"]) == int(branch_id):
        return
    raise HTTPException(status_code=403, detail="Access denied for this branch.")
