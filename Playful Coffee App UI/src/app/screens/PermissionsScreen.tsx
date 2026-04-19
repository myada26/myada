import React from "react";
import { useNavigate } from "react-router";
import { Button, Card } from "../components/UI";
import { Folder } from "lucide-react";
import { motion } from "motion/react";

export default function PermissionsScreen() {
  const navigate = useNavigate();

  return (
    <div className="flex-1 flex flex-col bg-[#F4EFEA] p-6 pt-16">
      
      {/* Top Graphic */}
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-center justify-center mb-10"
      >
        <div className="w-24 h-24 bg-[#1E3A8A]/10 rounded-3xl rotate-3 flex items-center justify-center border border-[#1E3A8A]/30">
          <Folder size={40} className="text-[#1E3A8A] -rotate-3" />
        </div>
      </motion.div>

      {/* Header Text */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
      >
        <h1 className="text-3xl font-bold mb-3 tracking-tight">One quick setup</h1>
        <p className="text-[#1F2937]/70 text-base leading-relaxed mb-10">
          To keep your classroom running without the internet, we need a quick setup.
        </p>
      </motion.div>

      {/* Permissions List */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.2 }}
      >
        <Card variant="basic" className="flex items-center gap-4 p-5 hover:bg-[#FAF8F5] transition-colors border-[#2D2D2D]/20">
          <div className="w-12 h-12 bg-[#F4EFEA] rounded-full border-[1.5px] border-[#2D2D2D] flex items-center justify-center shrink-0">
            <Folder size={20} className="text-[#1F2937]" />
          </div>
          <div className="flex-1">
            <h3 className="font-bold text-base mb-1">Storage access</h3>
            <p className="text-sm opacity-60 leading-snug">To save your lessons and progress for offline use.</p>
          </div>
        </Card>
      </motion.div>

      <div className="flex-1" />

      {/* Bottom Action */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="pb-8"
      >
        <Button variant="primary" className="w-full" onClick={() => navigate("/entry-point")}>
          Grant Access
        </Button>
      </motion.div>

    </div>
  );
}
