import React from "react";
import { useNavigate } from "react-router";
import { Button } from "../components/UI";
import { Compass } from "lucide-react";
import { motion } from "motion/react";

export default function EntryPointScreen() {
  const navigate = useNavigate();

  return (
    <div className="flex-1 flex flex-col bg-[#F4EFEA] p-6 pt-16">
      
      {/* Top Graphic */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex items-center justify-center mb-10"
      >
        <div className="w-32 h-32 bg-[#E89C1E]/10 rounded-full flex items-center justify-center border-[1.5px] border-[#E89C1E]/30 relative">
          <Compass size={56} className="text-[#E89C1E]" />
          <motion.div 
            animate={{ rotate: 360 }} 
            transition={{ duration: 10, repeat: Infinity, ease: "linear" }}
            className="absolute inset-0 rounded-full border border-dashed border-[#E89C1E]/50" 
          />
        </div>
      </motion.div>

      {/* Header Text */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="text-center mb-12"
      >
        <h1 className="text-3xl font-bold mb-4 tracking-tight">Where should we begin your journey?</h1>
        <p className="text-[#1F2937]/70 text-base leading-relaxed max-w-sm mx-auto">
          We'll personalize your path based on your answers.
        </p>
      </motion.div>

      <div className="flex-1" />

      {/* Bottom Actions */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="flex flex-col gap-4 pb-8"
      >
        <Button 
          variant="primary" 
          className="w-full text-lg h-16 shadow-lg shadow-[#1E3A8A]/20" 
          onClick={() => navigate("/register")}
        >
          Find My Starting Point
        </Button>
        <Button 
          variant="text" 
          className="w-full text-sm opacity-80" 
          onClick={() => navigate("/register")}
        >
          I'm a complete beginner, show me the basics.
        </Button>
      </motion.div>

    </div>
  );
}
