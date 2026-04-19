import React from "react";
import { useNavigate } from "react-router";
import { useForm } from "react-hook-form";
import { Button, Input, cn } from "../components/UI";
import { PasswordInput, PasswordStrengthBar } from "../components/FormElements";
import { motion } from "motion/react";

export default function RegisterScreen() {
  const navigate = useNavigate();
  const { register, handleSubmit, watch, formState: { errors } } = useForm();
  
  const passwordValue = watch("password", "");

  const onSubmit = (data: any) => {
    console.log("Register data", data);
    // TODO: Trigger Email OTP verification flow
    navigate("/dashboard");
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F4EFEA] p-6 pt-12 overflow-y-auto w-full no-scrollbar">
      
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-8"
      >
        <h1 className="text-3xl font-bold mb-2 tracking-tight">Create Account</h1>
        <p className="text-[#1F2937]/70 text-base">We're thrilled to have you join us.</p>
      </motion.div>

      <motion.form 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1 }}
        onSubmit={handleSubmit(onSubmit)} 
        className="flex flex-col gap-4 flex-1 w-full"
      >
        <div className="grid grid-cols-2 gap-4">
          <div>
            <Input 
              placeholder="Last Name" 
              {...register("lastName", { required: "Last name required" })}
              error={!!errors.lastName}
            />
            {errors.lastName && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.lastName.message as string}</p>}
          </div>
          <div>
            <Input 
              placeholder="First Name" 
              {...register("firstName", { required: "First name required" })}
              error={!!errors.firstName}
            />
            {errors.firstName && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.firstName.message as string}</p>}
          </div>
        </div>

        <div>
          <Input 
            type="date"
            placeholder="Date of Birth"
            {...register("dob", { required: "Date of Birth required" })}
            error={!!errors.dob}
            className={cn("w-full transition-colors", !watch("dob") && "text-[#1F2937]/40")}
          />
          {errors.dob && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.dob.message as string}</p>}
        </div>

        <div>
          <Input 
            type="email"
            placeholder="Email Address" 
            {...register("email", { 
              required: "Email is required", 
              pattern: { value: /^\S+@\S+$/i, message: "Invalid email" } 
            })}
            error={!!errors.email}
          />
          {errors.email && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.email.message as string}</p>}
        </div>

        <div>
          <PasswordInput 
            placeholder="Password"
            {...register("password", { required: "Password is required", minLength: { value: 6, message: "Minimum 6 characters" } })}
            error={!!errors.password}
          />
          <PasswordStrengthBar password={passwordValue} />
          {errors.password && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.password.message as string}</p>}
        </div>

        <div>
          <PasswordInput 
            placeholder="Confirm Password"
            {...register("confirmPassword", { 
              required: "Please confirm password",
              validate: (val) => val === passwordValue || "Passwords do not match"
            })}
            error={!!errors.confirmPassword}
          />
          {errors.confirmPassword && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.confirmPassword.message as string}</p>}
        </div>

        {/* TODO: CAPTCHA Integration Point */}

        <div className="flex flex-row items-center gap-3 mt-2 px-1">
          <input 
            type="checkbox" 
            id="terms"
            className="w-5 h-5 rounded border-[1.5px] border-[#2D2D2D]/20 checked:bg-[#1E3A8A] checked:border-[#1E3A8A] focus:ring-2 focus:ring-[#1E3A8A] transition-colors"
            {...register("terms", { required: "You must agree to the Terms" })}
          />
          <label htmlFor="terms" className="text-sm font-medium opacity-80 cursor-pointer">
            I agree to the Terms & Conditions
          </label>
        </div>
        {errors.terms && <p className="text-[#CA2B2C] text-xs px-2">{errors.terms.message as string}</p>}

        <div className="flex-1" />

        <div className="pb-8 pt-6">
          <Button type="submit" variant="primary" className="w-full h-16 text-lg">
            Create Account
          </Button>
          <div className="mt-6 text-center text-sm">
            <span className="opacity-70">Already have an account? </span>
            <button type="button" onClick={() => navigate("/login")} className="font-bold hover:underline">Log in</button>
          </div>
        </div>
      </motion.form>

    </div>
  );
}
