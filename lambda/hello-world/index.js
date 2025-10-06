/**
 * Sample Lambda function handler
 * This is a simple Hello World Lambda function
 */

exports.handler = async (event) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    const response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        body: JSON.stringify({
            message: 'Hello from Yeojeong Lambda!',
            timestamp: new Date().toISOString(),
            requestId: event.requestContext?.requestId || 'N/A',
            environment: process.env.ENVIRONMENT || 'dev'
        })
    };
    
    console.log('Response:', JSON.stringify(response, null, 2));
    return response;
};
