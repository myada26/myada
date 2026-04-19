import React from "react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import { motion } from "motion/react";

/** Utility to merge tailwind classes safely */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// ----------------------------------------------------------------------
// BUTTONS
// ----------------------------------------------------------------------
export type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "text";
  size?: "default" | "sm" | "lg";
  asChild?: boolean;
};

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "primary", size = "default", ...props }, ref) => {
    return (
      <motion.button
        ref={ref}
        whileTap={{ scale: 0.98 }}
        className={cn(
          "inline-flex items-center justify-center whitespace-nowrap rounded-full text-base font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#1E3A8A] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
          {
            "bg-[#1E3A8A] text-[#F4EFEA] hover:bg-[#152a65]":
              variant === "primary",
            "border-[1.5px] border-[#2D2D2D] bg-transparent text-[#1F2937] hover:bg-black/5":
              variant === "secondary",
            "bg-transparent text-[#1F2937] hover:bg-black/5":
              variant === "text",
            "h-14 px-8 py-4": size === "default",
            "h-10 px-6": size === "sm",
            "h-16 px-10 text-lg": size === "lg",
          },
          className
        )}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

// ----------------------------------------------------------------------
// INPUTS
// ----------------------------------------------------------------------
export type InputProps = React.InputHTMLAttributes<HTMLInputElement> & {
  error?: boolean;
};

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, error, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-14 w-full rounded-2xl border-[1.5px] bg-[#FAF8F5] px-4 py-2 text-base text-[#1F2937] transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-[#1F2937]/40 focus-visible:outline-none focus-visible:border-[#E89C1E] focus-visible:bg-white disabled:cursor-not-allowed disabled:opacity-50",
          error ? "border-[#CA2B2C] focus-visible:border-[#CA2B2C]" : "border-[#2D2D2D]/20",
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
Input.displayName = "Input";

// ----------------------------------------------------------------------
// CARDS
// ----------------------------------------------------------------------
export type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  variant?: "basic" | "list" | "highlight";
};

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = "basic", ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          "rounded-3xl border-[1.5px] border-[#2D2D2D] p-6 transition-all",
          {
            "bg-white": variant === "basic",
            "bg-[#FAF8F5] flex flex-row items-center p-4 rounded-2xl": variant === "list",
            "bg-[#E89C1E]/10 border-[#E89C1E]/50": variant === "highlight",
          },
          className
        )}
        {...props}
      />
    );
  }
);
Card.displayName = "Card";
