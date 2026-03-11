const MenuError = ({ message }: { message: string }) => {
  return (
    <div className="flex flex-col items-center justify-center py-24 px-4 text-center">
      {/* Decorative line */}
      <div className="flex items-center gap-4 mb-8 w-full max-w-xs">
        <span className="h-px flex-1 bg-[#d1b87a]/20" />
        <span className="text-[#d1b87a]/40 text-xs tracking-[0.4em]">✦</span>
        <span className="h-px flex-1 bg-[#d1b87a]/20" />
      </div>

      <p className="text-xs uppercase tracking-[0.4em] text-[#6b5e42] mb-3">
        Something went wrong
      </p>

      <h2 className="text-2xl font-light text-[#d1b87a] tracking-widest mb-4">
        Menu Unavailable
      </h2>

      <p className="text-sm text-[#9e8c6b] max-w-sm leading-relaxed mb-8">
        {message}
      </p>

      <button
        type="button"
        onClick={() => window.location.reload()}
        className="text-xs uppercase tracking-[0.3em] text-[#d1b87a] border border-[#d1b87a]/30 px-6 py-3 hover:border-[#d1b87a]/70 hover:bg-[#d1b87a]/5 transition-colors duration-300"
      >
        Try Again
      </button>

      {/* Decorative line */}
      <div className="flex items-center gap-4 mt-8 w-full max-w-xs">
        <span className="h-px flex-1 bg-[#d1b87a]/20" />
        <span className="text-[#d1b87a]/40 text-xs tracking-[0.4em]">✦</span>
        <span className="h-px flex-1 bg-[#d1b87a]/20" />
      </div>
    </div>
  );
};

export default MenuError;
