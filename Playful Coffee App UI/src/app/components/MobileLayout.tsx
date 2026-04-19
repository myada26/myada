import React from "react";
import { Outlet } from "react-router";

export function MobileLayout() {
  return (
    <div className="min-h-screen bg-[#F4EFEA] font-sans text-[#1F2937] flex justify-center">
      <div className="w-full max-w-md bg-[#F4EFEA] shadow-2xl relative flex flex-col min-h-screen overflow-x-hidden overflow-y-auto border-x-[1.5px] border-[#2D2D2D]/10">
        <Outlet />
      </div>
    </div>
  );
}
