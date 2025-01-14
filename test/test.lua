local cmd = vim.api.nvim_command
local vfn = vim.api.nvim_call_function
local uv  = vim.loop

cmd('packadd paq-nvim')

local testpath = vfn('stdpath', {'data'}) .. '/site/pack/test/'

local function reload_paq()
    local Pq
    package.loaded['paq-nvim'] = nil
    Pq = require('paq-nvim')
    Pq.setup {
        path = testpath,
    }
    return Pq
end

local Pq = reload_paq()
local paq = Pq.paq

paq{'rust-lang/rust.vim', opt=true}
paq{'JuliaEditorSupport/julia-vim', as='julia'}
paq{'junegunn/fzf', run=function() vfn('fzf#install', {}) end }
paq{'autozimu/LanguageClient-neovim',
    branch = 'next',
    run = 'bash install.sh',
    }

Pq.install()
cmd('sleep 20') -- plenty of time for plugins to download

assert(uv.fs_scandir(testpath .. 'opt/rust.vim'))
assert(uv.fs_scandir(testpath .. 'start/julia'))
assert(uv.fs_scandir(testpath .. 'start/fzf'))
assert(uv.fs_scandir(testpath .. 'start/LanguageClient-neovim'))

local function test_branch()
    local branch = 'next'
    local stdout = uv.new_pipe(false)
    local handle = uv.spawn( 'git', {
            cwd  = testpath .. 'start/LanguageClient-neovim',
            args = {'branch', '--show-current'}, -- FIXME: This might not work with some versions of git
            stdio = {nil, stout, nil},
        },
        function(code)
            assert(code == 0, "Paq-test: failed to get git branch")
            stdout:read_stop()
            stdout:close()
        end)
    stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
            assert(data == branch, string.format("Paq-test: %s does not equal %s", data, branch))
        end
    end)
end

test_branch()

cmd('sleep 20')
Pq = reload_paq()
Pq.clean()

print('Paq-test: FINISHED')
