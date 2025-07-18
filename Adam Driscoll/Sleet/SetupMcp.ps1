openapi-mcp-generator --input http://localhost:5000/agent-docs --output .\OneDrive\Desktop\mcp --base-url http://localhost:5000 --transport web
cd .\OneDrive\Desktop\mcp
npm i
npm run build
npm run start:web

<#
,
    "mcp": {
        "servers": {
            "PSU": {
                "url": "http://localhost:3000/sse"
            }
        }
    }
#>