// FILE: app/utils/protectCoach.ts

export const isCoach = (user: any) => {
    return user?.role === "coach" || user?.role === "head_coach";
  };
  
  export const isHeadCoach = (user: any) => {
    return user?.role === "head_coach";
  };