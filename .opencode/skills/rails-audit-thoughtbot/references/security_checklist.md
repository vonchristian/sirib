# Security Audit Checklist

## Critical Issues
### SQL Injection
DANGEROUS: `where("name = '#{params[:name]}'")`, `find_by_sql("SELECT * WHERE id = #{id}")`
SAFE: `where("name = ?", params[:name])`, `where(name: params[:name])`

### Mass Assignment
DANGEROUS: `params.permit!`, `User.new(params[:user])`
SAFE: Strong parameters via `params.require(:user).permit(:name, :email)`

### Command Injection
DANGEROUS: `system("convert #{params[:file]}")`, `` `ls #{input}` ``
SAFE: Use array form `system("convert", params[:file])`

### Path Traversal
DANGEROUS: `send_file(params[:filename])`, `File.read(params[:path])`
SAFE: Validate with `File.basename`, restrict to allowed directory

### Missing Authentication
Every controller should have authentication unless explicitly public.

## High Severity
### XSS
DANGEROUS: `<%= raw user_input %>`, `<%= user_input.html_safe %>`
SAFE: `<%= sanitize(user_input) %>` or auto-escaped output

### Insecure Direct Object References (IDOR)
DANGEROUS: `Document.find(params[:id])` (no authorization)
SAFE: `current_user.documents.find(params[:id])`

### Sensitive Data Exposure
Check for: logging passwords, exposing full objects in JSON, filter_parameters config

### Weak Cryptography
DANGEROUS: `Digest::MD5`, `Digest::SHA1` for passwords
SAFE: `BCrypt::Password.create`, `has_secure_password`

## Medium Severity
### CSRF
Check: `skip_before_action :verify_authenticity_token`, missing form tokens

### Session Security
Check: secure flag, httponly, same_site, expire_after

### Open Redirects
DANGEROUS: `redirect_to params[:return_to]`
SAFE: Validate against allowlist

## Audit Checklist
- [ ] All sensitive actions require authentication
- [ ] Resources scoped to authorized users
- [ ] Strong parameters used everywhere
- [ ] No SQL interpolation
- [ ] No `raw`/`html_safe` with user input
- [ ] JSON responses don't expose sensitive data
- [ ] Logs filtered for sensitive data
- [ ] HTTPS enforced in production
- [ ] Secure session configuration
- [ ] CSRF protection enabled
