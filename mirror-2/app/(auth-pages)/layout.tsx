export default async function Layout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <div className="grid gap-0 grid-cols-1 place-items-center min-h-screen justify-start">
      {children}
    </div>
  )
}
