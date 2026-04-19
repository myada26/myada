import React from "react";
import { useNavigate } from "react-router";
import { useForm } from "react-hook-form";
import { Button, Input } from "../components/UI";
import { PasswordInput } from "../components/FormElements";
import { motion } from "motion/react";
import { Code2 } from "lucide-react";

export default function LoginScreen() {
  const navigate = useNavigate();
  const { register, handleSubmit, formState: { errors } } = useForm();

  const onSubmit = (data: any) => {
    console.log("Login data", data);
    navigate("/dashboard");
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F4EFEA] p-6 pt-16">
      
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-12 flex flex-col items-center text-center mt-8"
      >
        <div className="w-16 h-16 bg-[#1E3A8A]/10 rounded-2xl flex items-center justify-center mb-6 border-[1.5px] border-[#1E3A8A]/20">
          <Code2 size={32} className="text-[#1E3A8A]" />
        </div>
        <h1 className="text-3xl font-bold mb-2 tracking-tight">Welcome back</h1>
        <p className="text-[#1F2937]/70 text-base">Log in to pick up where you left off.</p>
      </motion.div>

      <motion.form 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1 }}
        onSubmit={handleSubmit(onSubmit)} 
        className="flex flex-col gap-5 w-full flex-1"
      >
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
            {...register("password", { required: "Password is required" })}
            error={!!errors.password}
          />
          {errors.password && <p className="text-[#CA2B2C] text-xs mt-1 px-2">{errors.password.message as string}</p>}
          
          <div className="flex justify-end mt-2">
            <button 
              type="button" 
              className="text-sm font-medium text-[#1F2937]/70 hover:text-[#1E3A8A] transition-colors"
            >
              Forgot password?
            </button>
          </div>
        </div>

        <div className="flex-1" />

        <div className="pb-8">
          <Button type="submit" variant="primary" className="w-full h-16 text-lg shadow-lg shadow-[#1E3A8A]/20">
            Log in
          </Button>
          <div className="mt-8 text-center text-sm">
            <span className="opacity-70">Don't have an account? </span>
            <button type="button" onClick={() => navigate("/register")} className="font-bold hover:underline">Sign up</button>
          </div>
        </div>
      </motion.form>

    </div>
  );
}
