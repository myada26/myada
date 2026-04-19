import React, { useState } from "react";
import { Input, type InputProps } from "./UI";
import { Eye, EyeOff } from "lucide-react";
import { cn } from "./UI";

export const PasswordInput = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, error, ...props }, ref) => {
    const [show, setShow] = useState(false);

    return (
      <div className="relative">
        <Input
          type={show ? "text" : "password"}
          className={cn("pr-12", className)}
          error={error}
          ref={ref}
          {...props}
        />
        <button
          type="button"
          onClick={() => setShow(!show)}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-[#1F2937]/40 hover:text-[#1F2937]/80 transition-colors focus:outline-none"
        >
          {show ? <EyeOff size={20} /> : <Eye size={20} />}
        </button>
      </div>
    );
  }
);
PasswordInput.displayName = "PasswordInput";

export function PasswordStrengthBar({ password = "" }: { password?: string }) {
  // Simple logic for illustration: 
  // 0 = none, 1 = weak, 2 = fair, 3 = good, 4 = strong
  let strength = 0;
  if (password.length > 0) strength = 1;
  if (password.length >= 6) strength = 2;
  if (password.length >= 8 && /[A-Z]/.test(password)) strength = 3;
  if (password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password) && /[^A-Za-z0-9]/.test(password)) strength = 4;

  const barColor = (val: number) => {
    if (strength >= val) {
      if (strength === 1) return "bg-[#CA2B2C]"; // Weak (Red)
      if (strength === 2) return "bg-[#E89C1E]"; // Fair (Orange)
      if (strength === 3) return "bg-green-500"; // Good
      return "bg-[#1E3A8A]"; // Strong (Brand Blue)
    }
    return "bg-[#2D2D2D]/10";
  };

  if (password.length === 0) return null;

  return (
    <div className="flex gap-1 mt-2">
      <div className={cn("h-1.5 flex-1 rounded-full transition-colors", barColor(1))} />
      <div className={cn("h-1.5 flex-1 rounded-full transition-colors", barColor(2))} />
      <div className={cn("h-1.5 flex-1 rounded-full transition-colors", barColor(3))} />
      <div className={cn("h-1.5 flex-1 rounded-full transition-colors", barColor(4))} />
    </div>
  );
}
