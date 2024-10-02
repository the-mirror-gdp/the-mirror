export function ProgressIndeterminate() {
  return <div className='h-1.5 w-full bg-background overflow-hidden'>
    <div className='animate-progress w-full h-full bg-primary origin-left-right'></div>
  </div>
}
