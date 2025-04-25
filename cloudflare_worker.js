/**
 * Cloudflare Worker for handling file uploads and deletions for R2 bucket
 * Deploy this worker with bindings to your R2 bucket
 */

// Check if the request is for uploading a file
async function handleUpload(request, env) {
  try {
    // Parse the form data
    const formData = await request.formData();
    const file = formData.get('file');
    const key = formData.get('key');
    const accessKey = formData.get('accessKey');
    const secretKey = formData.get('secretKey');
    const bucket = formData.get('bucket');
    
    // Validate the required parameters
    if (!file || !key || !accessKey || !secretKey || !bucket) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Check if the credentials are valid
    if (accessKey !== env.ACCESS_KEY || secretKey !== env.SECRET_KEY) {
      return new Response(
        JSON.stringify({ error: 'Invalid credentials' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Upload the file to R2
    await env.MY_BUCKET.put(key, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
    });
    
    // Return the URL of the uploaded file
    return new Response(
      JSON.stringify({ 
        success: true, 
        key: key,
        url: `https://${request.headers.get('host')}/${key}`
      }),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || 'An error occurred during upload' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// Handle deleting a file
async function handleDelete(request, env) {
  try {
    // Parse the JSON body
    const { key, accessKey, secretKey, bucket } = await request.json();
    
    // Validate the required parameters
    if (!key || !accessKey || !secretKey || !bucket) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Check if the credentials are valid
    if (accessKey !== env.ACCESS_KEY || secretKey !== env.SECRET_KEY) {
      return new Response(
        JSON.stringify({ error: 'Invalid credentials' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Delete the file from R2
    await env.MY_BUCKET.delete(key);
    
    // Return success response
    return new Response(
      JSON.stringify({ success: true, key: key }),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || 'An error occurred during deletion' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// Serve a file from R2
async function serveFile(request, env, key) {
  try {
    // Get the object from R2
    const object = await env.MY_BUCKET.get(key);
    
    // If the object doesn't exist, return 404
    if (!object) {
      return new Response('Not Found', { status: 404 });
    }
    
    // Return the file with appropriate headers
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=31536000');
    
    return new Response(object.body, {
      headers,
    });
  } catch (error) {
    return new Response('Internal Server Error', { status: 500 });
  }
}

// Handle OPTIONS requests for CORS
function handleOptions(request) {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
    },
  });
}

// Main fetch handler
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // Handle preflight requests
    if (request.method === 'OPTIONS') {
      return handleOptions(request);
    }
    
    // Handle upload requests
    if (path === '/upload' && request.method === 'POST') {
      return handleUpload(request, env);
    }
    
    // Handle delete requests
    if (path === '/delete' && request.method === 'POST') {
      return handleDelete(request, env);
    }
    
    // Serve files (for any other path)
    return serveFile(request, env, path.substring(1)); // Remove the leading slash
  },
}; 