type PragmaInfo
    line :: Int
    used :: Bool
end

function lintlintpragma( ex::Expr, ctx::LintContext )
    if typeof( ex.args[2] ) <: String
        m = match( r"^((Print)|(Info)|(Warn)|(Error)) ((type)|(me)|(version)) +(.+)"s, ex.args[2] )
        if m != nothing
            action = m.captures[1]
            infotype = m.captures[6]
            rest_str = m.captures[10]
            if infotype == "type"
                v = parse( rest_str )
                if isexpr( v, :incomplete )
                    msg( ctx, 2, "Incomplete expression " * rest_str )
                    str = ""
                else
                    str = "typeof( " * rest_str * " ) == " * string( guesstype( v, ctx ) )
                end
            elseif infotype == "me"
                str = rest_str
            elseif infotype == "version"
                v = convert( VersionNumber, rest_str )
                reachable = ctx.versionreachable( v )
                if reachable
                    str = "Reachable by " * string(v)
                else
                    str = "Unreachable by " * string(v)
                end
            end

            if action == "Print"
                println( str )
            elseif action == "Info"
                msg( ctx, 0, str )
            elseif action == "Warn"
                msg( ctx, 1, str )
            else
                msg( ctx, 2, str )
            end
        else
            if !ctx.versionreachable( VERSION )
                return
            end
            ctx.callstack[end].pragmas[ ex.args[2] ] = PragmaInfo( ctx.line, false )
        end
    else
        msg( ctx, 2, "@lintpragma must be called using only string literals.")
    end
end

function pragmaexists( s::String, ctx::LintContext; deep=true )
    iend = deep ? 1 : length(ctx.callstack)
    for i in length( ctx.callstack ):-1:iend
        if haskey( ctx.callstack[i].pragmas, s )
            ctx.callstack[i].pragmas[s].used = true # it has been used
            return true
        end
    end
    return false
end
