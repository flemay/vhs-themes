local options = {
  autowrite = true,
  swapfile = false,
  backup = false,
  writebackup = false,
  wrap = true,
  number = true,
  tabstop = 4,
  shiftwidth = 2,
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
